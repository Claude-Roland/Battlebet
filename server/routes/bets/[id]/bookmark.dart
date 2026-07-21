import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/bets.dart';
import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/errors.dart';

/// Bookmark umschalten (an/aus) fuer den angemeldeten Nutzer.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  final uid = me['id'].toString();
  try {
    await db.runTx((tx) async {
      final b = await tx.execute(
        Sql.named('SELECT 1 FROM bets WHERE id = @id:uuid'),
        parameters: {'id': id},
      );
      if (b.isEmpty) throw HttpError('Bet not found.', status: 404);
      final del = await tx.execute(
        Sql.named('DELETE FROM bookmarks WHERE user_id = @uid:uuid AND bet_id = @id:uuid RETURNING 1'),
        parameters: {'uid': uid, 'id': id},
      );
      if (del.isEmpty) {
        await tx.execute(
          Sql.named('INSERT INTO bookmarks (user_id, bet_id) VALUES (@uid:uuid, @id:uuid)'),
          parameters: {'uid': uid, 'id': id},
        );
      }
    });
    return ok(await fetchBetDetail(id, uid));
  } on HttpError catch (e) {
    return fail(e.message, status: e.status);
  }
}
