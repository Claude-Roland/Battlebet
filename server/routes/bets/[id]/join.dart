import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/bets.dart';
import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/errors.dart';
import 'package:battlebet_server/src/limits.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  final uid = me['id'].toString();
  final userTier = (me['tier'] as num).toInt();

  try {
    await db.runTx((tx) async {
      final br = await tx.execute(
        Sql.named('SELECT * FROM bets WHERE id = @id:uuid'),
        parameters: {'id': id},
      );
      if (br.isEmpty) throw HttpError('Bet not found.', status: 404);
      final bet = br.first.toColumnMap();
      final status = (bet['status'] as num).toInt();
      final tier = (bet['tier'] as num).toInt();
      if (status >= 2) throw HttpError('This bet is closed.', status: 409);
      if (status == 1 && tier < 2) {
        throw HttpError('The entry window for this pot has closed.', status: 409);
      }
      if (userTier < tier) {
        throw HttpError('Your Bet Tier is too low for this pot.', status: 403);
      }
      final currency = (bet['currency'] as String).trim();
      if (currency != 'EUR') {
        throw HttpError('Only EUR test pots can be joined for now.', status: 409);
      }
      final stakeMinor = (bet['stake_minor'] as num).toInt();
      final entryCloses = bet['entry_closes_at'] as DateTime?;
      if (entryCloses != null && DateTime.now().toUtc().isAfter(entryCloses.toUtc())) {
        throw HttpError('The entry window for this pot has closed.', status: 409);
      }

      final mine = await tx.execute(
        Sql.named('SELECT 1 FROM participations WHERE bet_id = @id:uuid AND user_id = @uid:uuid'),
        parameters: {'id': id, 'uid': uid},
      );
      if (mine.isNotEmpty) throw HttpError('You already joined this bet.', status: 409);

      if (await activeParticipationCount(tx, uid) >= kMaxOverlappingBets) {
        throw HttpError(
          'You can be in at most $kMaxOverlappingBets bets at once.',
          status: 409,
        );
      }

      final cap = potCapMajor(tier);
      if (cap != null) {
        final cnt = await tx.execute(
          Sql.named('''
            SELECT (@seed + count(*))::int AS n
            FROM participations WHERE bet_id = @id:uuid
          '''),
          parameters: {'id': id, 'seed': (bet['seed_starters'] as num).toInt()},
        );
        final n = (cnt.first.toColumnMap()['n'] as num).toInt();
        if (n >= (cap * 100) ~/ stakeMinor) {
          throw HttpError('This pot is full.', status: 409);
        }
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

      await tx.execute(
        Sql.named('''
          INSERT INTO participations (bet_id, user_id, state, stake_minor, currency)
          VALUES (@id:uuid, @uid:uuid, 0, @stake, @cur)
        '''),
        parameters: {'id': id, 'uid': uid, 'stake': stakeMinor, 'cur': currency},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ledger (user_id, kind, amount_minor, currency,
            balance_after_minor, bet_id, note)
          VALUES (@uid:uuid, 2, -@stake:int8, @cur, @bal, @id:uuid, 'stake hold (join)')
        '''),
        parameters: {'uid': uid, 'stake': stakeMinor, 'cur': currency, 'bal': newBal, 'id': id},
      );
    });
    return ok(await fetchBetDetail(id, uid));
  } on HttpError catch (e) {
    return fail(e.message, status: e.status);
  }
}
