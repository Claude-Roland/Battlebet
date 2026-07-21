import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/errors.dart';

/// Loest einen Pot auf und zahlt die ECHTEN Durchhalter aus (Seed-Zahlen zaehlen NICHT).
/// Testmodus: nur der Ersteller darf ausloesen (spaeter automatisch am Enddatum).
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  final uid = me['id'].toString();

  try {
    final summary = await db.runTx((tx) async {
      final br = await tx.execute(
        Sql.named('SELECT * FROM bets WHERE id = @id:uuid'),
        parameters: {'id': id},
      );
      if (br.isEmpty) throw HttpError('Bet not found.', status: 404);
      final bet = br.first.toColumnMap();
      if (bet['creator_id'].toString() != uid) {
        throw HttpError('Only the creator can resolve this bet (testing).', status: 403);
      }
      if ((bet['status'] as num).toInt() >= 2) {
        throw HttpError('This bet is already resolved.', status: 409);
      }
      final stakeMinor = (bet['stake_minor'] as num).toInt();
      final feeBps = (bet['fee_bps'] as num).toInt();
      final currency = (bet['currency'] as String).trim();

      final parts = await tx.execute(
        Sql.named('SELECT user_id, state FROM participations WHERE bet_id = @id:uuid'),
        parameters: {'id': id},
      );
      final rows = parts.map((r) => r.toColumnMap()).toList();
      final starters = rows.length;
      final dropouts = rows.where((r) => (r['state'] as num).toInt() == 1).length;
      final finishers = rows.where((r) => (r['state'] as num).toInt() == 0).toList();
      final forfeited = stakeMinor * dropouts;
      final fee = (forfeited * feeBps / 10000).round();
      final surplus = forfeited - fee;
      final perFinisher = finishers.isEmpty ? 0 : surplus ~/ finishers.length;
      final payout = stakeMinor + perFinisher;

      for (final fr in finishers) {
        final fuid = fr['user_id'].toString();
        final w = await tx.execute(
          Sql.named('''
            UPDATE wallets SET balance_minor = balance_minor + @amt, updated_at = now()
            WHERE user_id = @uid:uuid AND currency = @cur
            RETURNING balance_minor
          '''),
          parameters: {'amt': payout, 'uid': fuid, 'cur': currency},
        );
        final bal = w.isEmpty ? 0 : (w.first.toColumnMap()['balance_minor'] as num).toInt();
        await tx.execute(
          Sql.named('''
            INSERT INTO ledger (user_id, kind, amount_minor, currency,
              balance_after_minor, bet_id, note)
            VALUES (@uid:uuid, 3, @amt, @cur, @bal, @id:uuid, 'payout (finisher)')
          '''),
          parameters: {'uid': fuid, 'amt': payout, 'cur': currency, 'bal': bal, 'id': id},
        );
        await tx.execute(
          Sql.named('''
            UPDATE participations SET state = 2, settled = true
            WHERE bet_id = @id:uuid AND user_id = @uid:uuid
          '''),
          parameters: {'id': id, 'uid': fuid},
        );
      }
      await tx.execute(
        Sql.named('UPDATE participations SET settled = true WHERE bet_id = @id:uuid AND state = 1'),
        parameters: {'id': id},
      );
      if (fee > 0) {
        await tx.execute(
          Sql.named('''
            INSERT INTO ledger (user_id, kind, amount_minor, currency,
              balance_after_minor, bet_id, note)
            SELECT id, 5, @fee, @cur, 0, @id:uuid, 'platform fee'
            FROM users WHERE username_lc = 'battlebet'
          '''),
          parameters: {'fee': fee, 'cur': currency, 'id': id},
        );
      }
      await tx.execute(
        Sql.named('UPDATE bets SET status = 2, resolved_at = now() WHERE id = @id:uuid'),
        parameters: {'id': id},
      );
      return {
        'starters': starters,
        'dropouts': dropouts,
        'finishers': finishers.length,
        'stakeMinor': stakeMinor,
        'forfeitedMinor': forfeited,
        'feeMinor': fee,
        'payoutPerFinisherMinor': payout,
        'currency': currency,
      };
    });
    return ok(summary);
  } on HttpError catch (e) {
    return fail(e.message, status: e.status);
  }
}
