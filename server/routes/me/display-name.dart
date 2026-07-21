import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final token = bearer(context);
  if (token == null) return fail('Not authenticated.', status: 401);
  final body = await readJson(context);
  final name = (body['displayName'] as String?)?.trim() ?? '';
  if (name.length > 40) return fail('Display name is too long.');

  final res = await db.execute(
    Sql.named('''
      WITH s AS (
        SELECT user_id FROM sessions WHERE token = @t AND expires_at > now()
      )
      UPDATE users u SET display_name = @name
      FROM s WHERE u.id = s.user_id
      RETURNING u.id, u.username, u.display_name, u.tier
    '''),
    parameters: {'t': token, 'name': name},
  );
  if (res.isEmpty) return fail('Not authenticated.', status: 401);
  final row = res.first.toColumnMap();
  final display = (row['display_name'] as String?)?.trim() ?? '';
  return ok({
    'user': {
      'id': row['id'].toString(),
      'username': row['username'],
      'displayName': display.isEmpty ? row['username'] : display,
      'tier': (row['tier'] as num).toInt(),
      'tierLabel': tierLabel((row['tier'] as num).toInt()),
    },
  });
}
