import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/bets.dart';
import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/errors.dart';

/// Admin: kuratierte Wette anlegen — FREIER Name (umgeht den Auto-Namen),
/// nur fuer Personal (is_staff). Der Ersteller wettet NICHT mit (keine
/// Teilnahme, kein Einsatz-Abzug); Nutzer treten spaeter bei. Tag = special (3).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final me = await authedStaff(context);
  if (me == null) return fail('Staff only.', status: 403);
  final uid = me['id'].toString();

  final body = await readJson(context);
  final name = (body['name'] as String?)?.trim() ?? '';
  final sport = (body['sport'] as num?)?.toInt() ?? 0;
  final distanceKm = (body['distanceKm'] as num?)?.toDouble() ?? 0;
  final ipw = (body['iterationsPerWeek'] as num?)?.toInt() ?? 0;
  final days = (body['expirationDays'] as num?)?.toInt() ?? 0;
  final stakeMinor = (body['stakeMinor'] as num?)?.toInt() ?? 0;
  final currency = ((body['currency'] as String?) ?? 'EUR').trim().toUpperCase();
  final tier = (body['tier'] as num?)?.toInt() ?? 0;

  if (name.isEmpty) return fail('Please give the curated bet a name.');
  if (sport < 0 || sport > 5) return fail('Unknown sport.');
  if (tier < 0 || tier > 2) return fail('Unknown tier.');
  if (currency != 'EUR') return fail('Only EUR is supported in test mode.');
  if (distanceKm <= 0) return fail('Distance must be positive.');
  if (ipw < 1 || ipw > 21) return fail('Iterations per week out of range.');
  if (days < 7 || days % 7 != 0) {
    return fail('Duration must be whole weeks (a multiple of 7 days).');
  }
  if (days > 3640) return fail('Duration is too long.');
  if (stakeMinor <= 0) return fail('Stake must be positive.');

  try {
    final betId = await db.runTx((tx) async {
      final dup = await tx.execute(
        Sql.named('SELECT 1 FROM bets WHERE name = @n LIMIT 1'),
        parameters: {'n': name},
      );
      if (dup.isNotEmpty) {
        throw HttpError('A bet with this name already exists.', status: 409);
      }
      final b = await tx.execute(
        Sql.named('''
          INSERT INTO bets (creator_id, name, sport, distance_km, iterations_per_week,
            expiration_days, stake_minor, currency, tier, fee_bps, tag, status,
            entry_closes_at, starts_at, ends_at, min_participants)
          VALUES (@uid:uuid, @name, @sport, @dist, @ipw, @days:int4, @stake, @cur, @tier:int4,
            1000, 3,
            CASE WHEN @tier:int4 < 2 THEN 0 ELSE 1 END,
            CASE WHEN @tier:int4 < 2 THEN now() + interval '7 days' ELSE NULL END,
            CASE WHEN @tier:int4 < 2 THEN now() + interval '7 days' ELSE now() END,
            CASE WHEN @tier:int4 < 2
                 THEN now() + interval '7 days' + make_interval(days => @days:int4)
                 ELSE now() + make_interval(days => @days:int4) END,
            3)
          RETURNING id
        '''),
        parameters: {
          'uid': uid, 'name': name, 'sport': sport, 'dist': distanceKm,
          'ipw': ipw, 'days': days, 'stake': stakeMinor, 'cur': currency, 'tier': tier,
        },
      );
      return b.first.toColumnMap()['id'].toString();
    });
    return ok(await fetchBetDetail(betId, uid), status: 201);
  } on HttpError catch (e) {
    return fail(e.message, status: e.status);
  }
}
