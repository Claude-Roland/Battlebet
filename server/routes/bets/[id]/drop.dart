import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/bets.dart';
import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/errors.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  final uid = me['id'].toString();

  try {
    await db.runTx((tx) async {
      final br = await tx.execute(
        Sql.named('SELECT status FROM bets WHERE id = @id:uuid'),
        parameters: {'id': id},
      );
      if (br.isEmpty) throw HttpError('Bet not found.', status: 404);
      if ((br.first.toColumnMap()['status'] as num).toInt() >= 2) {
        throw HttpError('This bet is closed.', status: 409);
      }
      final p = await tx.execute(
        Sql.named('SELECT state FROM participations WHERE bet_id = @id:uuid AND user_id = @uid:uuid'),
        parameters: {'id': id, 'uid': uid},
      );
      if (p.isEmpty) throw HttpError('You are not in this bet.', status: 404);
      if ((p.first.toColumnMap()['state'] as num).toInt() != 0) {
        throw HttpError('You already left or finished this bet.', status: 409);
      }
      // Aussteigen: Einsatz ist beim Beitreten bereits gehalten -> bleibt im Pot (verwirkt).
      await tx.execute(
        Sql.named('UPDATE participations SET state = 1 WHERE bet_id = @id:uuid AND user_id = @uid:uuid'),
        parameters: {'id': id, 'uid': uid},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ledger (user_id, kind, amount_minor, currency, balance_after_minor, bet_id, note)
          SELECT p.user_id, 4, 0, p.currency, COALESCE(w.balance_minor, 0), @id:uuid,
                 'dropped out (stake forfeited)'
          FROM participations p
          LEFT JOIN wallets w ON w.user_id = p.user_id AND w.currency = p.currency
          WHERE p.bet_id = @id:uuid AND p.user_id = @uid:uuid
        '''),
        parameters: {'id': id, 'uid': uid},
      );
    });
    return ok(await fetchBetDetail(id, uid));
  } on HttpError catch (e) {
    return fail(e.message, status: e.status);
  }
}
