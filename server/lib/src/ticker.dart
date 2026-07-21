import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/settle.dart';

/// Aktivitaetstyp aus dem Tempo (Sek/km): 0=walking, 1=jogging, 2=running.
/// Schwellen wie in der App (running <=6:00, jogging <=9:00).
int classifyPace(int paceSecPerKm) {
  if (paceSecPerKm <= 0) return 0;
  if (paceSecPerKm <= 360) return 2;
  if (paceSecPerKm <= 540) return 1;
  return 0;
}

/// Fuss-Sportarten (nach Tempo/Aktivitaet abgeglichen): jogging(0), running(1),
/// wandern(5). Andere Sportarten werden exakt nach sport abgeglichen.
bool isFootSport(int sport) => sport == 0 || sport == 1 || sport == 5;

/// Geforderter Aktivitaetstyp einer Fuss-Wette.
int requiredActivityForSport(int sport) => switch (sport) {
      1 => 2, // running
      0 => 1, // jogging
      5 => 0, // wandern
      _ => 1,
    };

/// Ein Ticker-Durchlauf: Anmeldefenster schliessen, Wochen-Checkpoints,
/// faellige Wetten aufloesen. In Produktion per Cron, im Test manuell.
Future<Map<String, dynamic>> runTicker() async {
  final entry = await _closeEntryWindows();
  final dropped = await _weeklyCheckpoints();
  final resolved = await _resolveEnded();
  return {
    'entryStarted': entry['started'],
    'entryCancelled': entry['cancelled'],
    'weeklyDropped': dropped,
    'resolved': resolved,
  };
}

Future<Map<String, List<String>>> _closeEntryWindows() async {
  final due = await db.execute(
    'SELECT id FROM bets '
    'WHERE status = 0 AND entry_closes_at IS NOT NULL AND entry_closes_at <= now()',
  );
  final started = <String>[];
  final cancelled = <String>[];
  for (final row in due) {
    final betId = row.toColumnMap()['id'].toString();
    final outcome = await db.runTx((tx) async {
      final cntRes = await tx.execute(
        Sql.named('''
          SELECT count(*) FILTER (WHERE state = 0)::int AS active,
                 (SELECT min_participants FROM bets WHERE id = @id:uuid) AS minp
          FROM participations WHERE bet_id = @id:uuid
        '''),
        parameters: {'id': betId},
      );
      final m = cntRes.first.toColumnMap();
      if ((m['active'] as num).toInt() >= (m['minp'] as num).toInt()) {
        await tx.execute(
          Sql.named('UPDATE bets SET status = 1 WHERE id = @id:uuid'),
          parameters: {'id': betId},
        );
        return 'started';
      }
      final parts = await tx.execute(
        Sql.named('SELECT user_id, stake_minor, currency FROM participations '
            'WHERE bet_id = @id:uuid AND state = 0'),
        parameters: {'id': betId},
      );
      for (final p in parts) {
        final pm = p.toColumnMap();
        final puid = pm['user_id'].toString();
        final stake = (pm['stake_minor'] as num).toInt();
        final cur = (pm['currency'] as String).trim();
        final w = await tx.execute(
          Sql.named('''
            UPDATE wallets SET balance_minor = balance_minor + @amt, updated_at = now()
            WHERE user_id = @uid:uuid AND currency = @cur RETURNING balance_minor
          '''),
          parameters: {'amt': stake, 'uid': puid, 'cur': cur},
        );
        final bal = w.isEmpty ? 0 : (w.first.toColumnMap()['balance_minor'] as num).toInt();
        await tx.execute(
          Sql.named('''
            INSERT INTO ledger (user_id, kind, amount_minor, currency,
              balance_after_minor, bet_id, note)
            VALUES (@uid:uuid, 6, @amt, @cur, @bal, @id:uuid, 'refund (under minimum)')
          '''),
          parameters: {'uid': puid, 'amt': stake, 'cur': cur, 'bal': bal, 'id': betId},
        );
      }
      await tx.execute(
        Sql.named('UPDATE participations SET settled = true WHERE bet_id = @id:uuid'),
        parameters: {'id': betId},
      );
      await tx.execute(
        Sql.named('UPDATE bets SET status = 3, resolved_at = now() WHERE id = @id:uuid'),
        parameters: {'id': betId},
      );
      return 'cancelled';
    });
    (outcome == 'started' ? started : cancelled).add(betId);
  }
  return {'started': started, 'cancelled': cancelled};
}

int _pensumForWeek(int ipw, DateTime weekStart, DateTime weekEnd, DateTime joinedAt) {
  if (!joinedAt.isAfter(weekStart)) return ipw; // beigetreten vor/mit Wochenbeginn
  if (!joinedAt.isBefore(weekEnd)) return 0; // erst nach dieser Woche beigetreten
  final weekSecs = weekEnd.difference(weekStart).inSeconds;
  final remaining = weekEnd.difference(joinedAt).inSeconds;
  if (remaining <= 0) return 0;
  return (ipw * remaining + weekSecs - 1) ~/ weekSecs; // aufgerundet
}

Future<List<Map<String, dynamic>>> _weeklyCheckpoints() async {
  final bets = await db.execute(
    'SELECT id, starts_at, expiration_days, iterations_per_week, sport, '
    'distance_km::float8 AS distance_km, weeks_checked FROM bets WHERE status = 1',
  );
  final dropped = <Map<String, dynamic>>[];
  final now = DateTime.now().toUtc();
  for (final row in bets) {
    final b = row.toColumnMap();
    final betId = b['id'].toString();
    final startsAt = (b['starts_at'] as DateTime).toUtc();
    final weeksTotal = (b['expiration_days'] as num).toInt() ~/ 7;
    final ipw = (b['iterations_per_week'] as num).toInt();
    final sport = (b['sport'] as num).toInt();
    final reqMeters = ((b['distance_km'] as num).toDouble() * 1000).round();
    final weeksChecked = (b['weeks_checked'] as num).toInt();
    var weeksElapsed = now.difference(startsAt).inSeconds ~/ (7 * 86400);
    if (weeksElapsed > weeksTotal) weeksElapsed = weeksTotal;
    if (weeksElapsed <= weeksChecked) continue;
    final foot = isFootSport(sport);
    final reqActivity = requiredActivityForSport(sport);
    await db.runTx((tx) async {
      for (var w = weeksChecked; w < weeksElapsed; w++) {
        final weekStart = startsAt.add(Duration(days: 7 * w));
        final weekEnd = startsAt.add(Duration(days: 7 * (w + 1)));
        final parts = await tx.execute(
          Sql.named('SELECT id, user_id, joined_at FROM participations '
              'WHERE bet_id = @bid:uuid AND state = 0'),
          parameters: {'bid': betId},
        );
        for (final pr in parts) {
          final p = pr.toColumnMap();
          final pid = p['id'].toString();
          final uid = p['user_id'].toString();
          final joinedAt = (p['joined_at'] as DateTime).toUtc();
          final required = _pensumForWeek(ipw, weekStart, weekEnd, joinedAt);
          if (required <= 0) continue;
          final matchCond = foot ? 'activity >= @ra:int4' : 'sport = @bs:int4';
          final params = <String, dynamic>{
            'uid': uid, 'ws': weekStart, 'we': weekEnd, 'rm': reqMeters,
          };
          if (foot) {
            params['ra'] = reqActivity;
          } else {
            params['bs'] = sport;
          }
          final cRes = await tx.execute(
            Sql.named('''
              SELECT count(*)::int AS n FROM runs
              WHERE user_id = @uid:uuid
                AND recorded_at >= @ws:timestamptz AND recorded_at < @we:timestamptz
                AND distance_meters >= @rm:int4 AND $matchCond
            '''),
            parameters: params,
          );
          final n = (cRes.first.toColumnMap()['n'] as num).toInt();
          if (n < required) {
            await tx.execute(
              Sql.named('UPDATE participations SET state = 1 WHERE id = @pid:uuid'),
              parameters: {'pid': pid},
            );
            await tx.execute(
              Sql.named('''
                INSERT INTO ledger (user_id, kind, amount_minor, currency,
                  balance_after_minor, bet_id, note)
                SELECT p.user_id, 4, 0, p.currency, COALESCE(w.balance_minor, 0),
                       @bid:uuid, 'auto-dropout (week pensum missed)'
                FROM participations p
                LEFT JOIN wallets w ON w.user_id = p.user_id AND w.currency = p.currency
                WHERE p.id = @pid:uuid
              '''),
              parameters: {'pid': pid, 'bid': betId},
            );
            dropped.add({'bet': betId, 'user': uid, 'week': w, 'did': n, 'needed': required});
          }
        }
      }
      await tx.execute(
        Sql.named('UPDATE bets SET weeks_checked = @wc:int4 WHERE id = @bid:uuid'),
        parameters: {'wc': weeksElapsed, 'bid': betId},
      );
    });
  }
  return dropped;
}

Future<List<Map<String, dynamic>>> _resolveEnded() async {
  final due = await db.execute(
    'SELECT id FROM bets WHERE status = 1 AND ends_at IS NOT NULL AND ends_at <= now()',
  );
  final resolved = <Map<String, dynamic>>[];
  for (final row in due) {
    final betId = row.toColumnMap()['id'].toString();
    resolved.add(await db.runTx((tx) => resolveBet(tx, betId)));
  }
  return resolved;
}
