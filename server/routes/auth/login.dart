import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final body = await readJson(context);
  final username = (body['username'] as String?)?.trim() ?? '';
  final password = (body['password'] as String?) ?? '';
  if (username.isEmpty || password.isEmpty) {
    return fail('Please enter username and password.');
  }

  final res = await db.execute(
    Sql.named('''
      SELECT u.id, u.username, u.display_name, u.tier, u.password_hash,
             w.balance_minor, w.currency, w.is_test
      FROM users u
      JOIN wallets w ON w.user_id = u.id AND w.currency = 'EUR'
      WHERE u.username_lc = @u
    '''),
    parameters: {'u': username.toLowerCase()},
  );
  if (res.isEmpty) {
    return fail('No account with this username.', status: 401);
  }
  final row = res.first.toColumnMap();
  if (!checkPassword(password, row['password_hash'] as String)) {
    return fail('Wrong password.', status: 401);
  }

  final token = newToken();
  await db.execute(
    Sql.named('''
      INSERT INTO sessions (token, user_id, expires_at)
      SELECT @t, id, now() + interval '365 days'
      FROM users WHERE username_lc = @u
    '''),
    parameters: {'t': token, 'u': username.toLowerCase()},
  );

  return ok({'token': token, ...profileJson(row)});
}
