import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/bets.dart';
import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/errors.dart';
import 'package:battlebet_server/src/limits.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _list(context),
    HttpMethod.post => _create(context),
    _ => fail('Method not allowed', status: 405),
  };
}

Future<Response> _list(RequestContext context) async {
  final me = await authed(context);
  final meId = me?['id']?.toString() ?? zeroUuid;
  return ok({'bets': await listBets(meId)});
}

Future<Response> _create(RequestContext context) async {
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  final uid = me['id'].toString();
  final userTier = (me['tier'] as num).toInt();

  final body = await readJson(context);
  final name = (body['name'] as String?)?.trim() ?? '';
  final sport = (body['sport'] as num?)?.toInt() ?? 0;
  final distanceKm = (body['distanceKm'] as num?)?.toDouble() ?? 0;
  final ipw = (body['iterationsPerWeek'] as num?)?.toInt() ?? 0;
  final days = (body['expirationDays'] as num?)?.toInt() ?? 0;
  final stakeMinor = (body['stakeMinor'] as num?)?.toInt() ?? 0;
  final currency = ((body['currency'] as String?) ?? 'EUR').trim().toUpperCase();
  final tier = (body['tier'] as num?)?.toInt() ?? 0;

  if (name.isEmpty) return fail('Please give the bet a name.');
  if (sport < 0 || sport > 4) return fail('Unknown sport.');
  if (tier < 0 || tier > 2) return fail('Unknown tier.');
  if (currency != 'EUR') return fail('Only EUR is supported in test mode.');
  if (distanceKm <= 0) return fail('Distance must be positive.');
  if (ipw < 1 || ipw > 21) return fail('Iterations per week out of range.');
  if (days < 7 || days % 7 != 0) {
    return fail('Duration must be whole weeks (a multiple of 7 days).');
  }
  if (days > 3640) return fail('Duration is too long.');
  if (stakeMinor <= 0) return fail('Stake must be positive.');
  if (userTier < tier) {
    return fail('Your Bet Tier is too low to open this pot.', status: 403);
  }

  try {
    final betId = await db.runTx((tx) async {
      if (await activeParticipationCount(tx, uid) >= kMaxOverlappingBets) {
        throw HttpError(
          'You can be in at most $kMaxOverlappingBets bets at once.',
          status: 409,
        );
      }
      final w = await tx.execute(
        Sql.named('''
          UPDATE wallets SET balance_minor = balance_minor - @stake, updated_at = now()
          WHERE user_id = @uid:uuid AND currency = @cur AND balance_minor >= @stake
          RETURNING balance_minor
        '''),
        parameters: {'stake': stakeMinor, 'uid': uid, 'cur': currency},
      );
      if (w.isEmpty) throw HttpError('Not enough balance for the stake.', status: 409);
      final newBal = (w.first.toColumnMap()['balance_minor'] as num).toInt();

      final b = await tx.execute(
        Sql.named('''
          INSERT INTO bets (creator_id, name, sport, distance_km, iterations_per_week,
            expiration_days, stake_minor, currency, tier, fee_bps, tag, status,
            entry_closes_at, starts_at, ends_at, min_participants)
          VALUES (@uid:uuid, @name, @sport, @dist, @ipw, @days:int4, @stake, @cur, @tier:int4,
            1000, 0,
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
      final bid = b.first.toColumnMap()['id'].toString();

      await tx.execute(
        Sql.named('''
          INSERT INTO participations (bet_id, user_id, state, stake_minor, currency)
          VALUES (@bid:uuid, @uid:uuid, 0, @stake, @cur)
        '''),
        parameters: {'bid': bid, 'uid': uid, 'stake': stakeMinor, 'cur': currency},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ledger (user_id, kind, amount_minor, currency,
            balance_after_minor, bet_id, note)
          VALUES (@uid:uuid, 2, -@stake:int8, @cur, @bal, @bid:uuid, 'stake hold (create bet)')
        '''),
        parameters: {'uid': uid, 'stake': stakeMinor, 'cur': currency, 'bal': newBal, 'bid': bid},
      );
      return bid;
    });
    return ok(await fetchBetDetail(betId, uid), status: 201);
  } on HttpError catch (e) {
    return fail(e.message, status: e.status);
  }
}
