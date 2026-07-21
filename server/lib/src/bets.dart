import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/db.dart';

/// Platzhalter-UUID fuer "nicht angemeldet" (matcht keinen Nutzer).
const zeroUuid = '00000000-0000-0000-0000-000000000000';

/// Tier-Deckel in ganzen Waehrungseinheiten (null = unbegrenzt, Bet Tier 3).
int? potCapMajor(int tier) => switch (tier) {
      0 => 500,
      1 => 2000,
      _ => null,
    };

const _potTierLabels = [
  'Tier 1 · up to 500',
  'Tier 2 · up to 2000',
  'Unlimited',
];
const _potTierShort = ['Tier 1', 'Tier 2', 'Unlimited'];
const _phases = ['gathering', 'running', 'resolved', 'cancelled'];
int _clamp(int v, int max) => v < 0 ? 0 : (v > max ? max : v);
String potTierLabel(int t) => _potTierLabels[_clamp(t, 2)];
String potTierShort(int t) => _potTierShort[_clamp(t, 2)];
String phaseLabel(int status) => _phases[_clamp(status, 3)];

/// Pot-Oekonomie in Integer-Cent — spiegelt models/bet_economics.dart der App.
Map<String, dynamic> economy({
  required int stakeMinor,
  required int feeBps,
  required int tier,
  required int starters,
  required int dropouts,
}) {
  final capMajor = potCapMajor(tier);
  final potCapMinor = capMajor == null ? null : capMajor * 100;
  final maxStarters =
      (potCapMinor == null || stakeMinor <= 0) ? null : potCapMinor ~/ stakeMinor;
  final isFull = maxStarters != null && starters >= maxStarters;
  final finishers = (starters - dropouts) < 1 ? 1 : (starters - dropouts);
  final potMinor = stakeMinor * starters;
  final forfeitedMinor = stakeMinor * dropouts;
  final feeMinor = (forfeitedMinor * feeBps / 10000).round();
  final surplusMinor = forfeitedMinor - feeMinor;
  final surplusPerFinisher = surplusMinor ~/ finishers;
  final payoutPerFinisherMinor = stakeMinor + surplusPerFinisher;
  final increasePct =
      stakeMinor == 0 ? 0.0 : (payoutPerFinisherMinor / stakeMinor - 1) * 100;
  return {
    'potMinor': potMinor,
    'feeMinor': feeMinor,
    'payoutPerFinisherMinor': payoutPerFinisherMinor,
    'increasePct': double.parse(increasePct.toStringAsFixed(2)),
    'maxStarters': maxStarters,
    'isFull': isFull,
    'finishers': finishers,
  };
}

/// Baut die JSON einer Wetten-Zeile (starters/dropouts sind bereits seed+real kombiniert).
Map<String, dynamic> betJson(Map<String, dynamic> r, {int? myState}) {
  final stakeMinor = (r['stake_minor'] as num).toInt();
  final feeBps = (r['fee_bps'] as num).toInt();
  final tier = (r['tier'] as num).toInt();
  final starters = (r['starters'] as num).toInt();
  final dropouts = (r['dropouts'] as num).toInt();
  final status = (r['status'] as num).toInt();
  final eco = economy(
    stakeMinor: stakeMinor,
    feeBps: feeBps,
    tier: tier,
    starters: starters,
    dropouts: dropouts,
  );
  return {
    'id': r['id'].toString(),
    'name': r['name'],
    'sport': (r['sport'] as num).toInt(),
    'distanceKm': (r['distance_km'] as num).toDouble(),
    'iterationsPerWeek': (r['iterations_per_week'] as num).toInt(),
    'expirationDays': (r['expiration_days'] as num).toInt(),
    'stakeMinor': stakeMinor,
    'currency': (r['currency'] as String).trim(),
    'tier': tier,
    'tierLabel': potTierLabel(tier),
    'tierShort': potTierShort(tier),
    'feeBps': feeBps,
    'tag': (r['tag'] as num).toInt(),
    'status': status,
    'phase': phaseLabel(status),
    'createdAt': (r['created_at'] as DateTime).toUtc().toIso8601String(),
    'startsAt': (r['starts_at'] as DateTime?)?.toUtc().toIso8601String(),
    'endsAt': (r['ends_at'] as DateTime?)?.toUtc().toIso8601String(),
    'entryClosesAt': (r['entry_closes_at'] as DateTime?)?.toUtc().toIso8601String(),
    'minParticipants': (r['min_participants'] as num).toInt(),
    'realStarters': (r['real_starters'] as num).toInt(),
    'starters': starters,
    'dropouts': dropouts,
    'joined': myState != null,
    if (myState != null) 'myState': myState,
    ...eco,
  };
}

const _selectBet = '''
  b.id, b.name, b.sport, b.distance_km::float8 AS distance_km,
  b.iterations_per_week, b.expiration_days, b.stake_minor, b.currency,
  b.tier, b.fee_bps, b.tag, b.status, b.created_at, b.starts_at, b.ends_at,
  b.entry_closes_at, b.min_participants,
  COALESCE(agg.real_starters, 0) AS real_starters,
  (b.seed_starters + COALESCE(agg.real_starters, 0)) AS starters,
  (b.seed_dropouts + COALESCE(agg.real_dropouts, 0)) AS dropouts,
  my.state AS my_state
''';

const _joinAgg = '''
  LEFT JOIN (
    SELECT bet_id, count(*) AS real_starters,
           count(*) FILTER (WHERE state = 1) AS real_dropouts
    FROM participations GROUP BY bet_id
  ) agg ON agg.bet_id = b.id
  LEFT JOIN participations my ON my.bet_id = b.id AND my.user_id = @me:uuid
''';

/// Liste aller nicht abgebrochenen Wetten (neueste zuerst), mit Oekonomie.
Future<List<Map<String, dynamic>>> listBets(String meId) async {
  final res = await db.execute(
    Sql.named('''
      SELECT $_selectBet FROM bets b $_joinAgg
      WHERE b.status <> 3
      ORDER BY b.created_at DESC
    '''),
    parameters: {'me': meId},
  );
  return res.map((row) {
    final r = row.toColumnMap();
    final ms = r['my_state'];
    return betJson(r, myState: ms == null ? null : (ms as num).toInt());
  }).toList();
}

/// Detail einer einzelnen Wette (oder null).
Future<Map<String, dynamic>?> fetchBetDetail(String id, String meId) async {
  final res = await db.execute(
    Sql.named('''
      SELECT $_selectBet FROM bets b $_joinAgg
      WHERE b.id = @id:uuid
    '''),
    parameters: {'me': meId, 'id': id},
  );
  if (res.isEmpty) return null;
  final r = res.first.toColumnMap();
  final ms = r['my_state'];
  return betJson(r, myState: ms == null ? null : (ms as num).toInt());
}
