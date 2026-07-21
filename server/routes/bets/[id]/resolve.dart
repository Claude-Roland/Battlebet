import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/errors.dart';
import 'package:battlebet_server/src/settle.dart';

/// Manuelles Aufloesen (nur Ersteller, Testmodus). Regulaer loest der Ticker
/// die Wette am Enddatum automatisch auf.
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
        Sql.named('SELECT creator_id, status FROM bets WHERE id = @id:uuid'),
        parameters: {'id': id},
      );
      if (br.isEmpty) throw HttpError('Bet not found.', status: 404);
      final bet = br.first.toColumnMap();
      if (bet['creator_id'].toString() != uid) {
        throw HttpError('Only the creator can resolve this bet (testing).', status: 403);
      }
      final status = (bet['status'] as num).toInt();
      if (status >= 2) throw HttpError('This bet is already resolved.', status: 409);
      if (status != 1) throw HttpError('This bet has not started yet.', status: 409);
      return resolveBet(tx, id);
    });
    return ok(summary);
  } on HttpError catch (e) {
    return fail(e.message, status: e.status);
  }
}
