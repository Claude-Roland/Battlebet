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
  if (username.length < 3) {
    return fail('Username must be at least 3 characters.');
  }
  if (password.length < 6) {
    return fail('Password must be at least 6 characters.');
  }

  final exists = await db.execute(
    Sql.named('SELECT 1 FROM users WHERE username_lc = @u'),
    parameters: {'u': username.toLowerCase()},
  );
  if (exists.isNotEmpty) {
    return fail('This username is already taken.', status: 409);
  }

  final token = newToken();
  final hash = hashPassword(password);
  const startCredits = 10000; // 100.00 EUR Test-Credits zum Start

  final res = await db.execute(
    Sql.named('''
      WITH nu AS (
        INSERT INTO users (username, username_lc, password_hash, display_name, tier)
        VALUES (@u, @ulc, @ph, '', 2)
        RETURNING id, username, display_name, tier
      ), nw AS (
        INSERT INTO wallets (user_id, currency, balance_minor, is_test)
        SELECT id, 'EUR', @start, true FROM nu
        RETURNING user_id, balance_minor, currency, is_test
      ), nl AS (
        INSERT INTO ledger (user_id, kind, amount_minor, currency,
                            balance_after_minor, note)
        SELECT id, 0, @start, 'EUR', @start, 'welcome test credits' FROM nu
      ), ns AS (
        INSERT INTO sessions (token, user_id, expires_at)
        SELECT @t, id, now() + interval '365 days' FROM nu
      )
      SELECT nu.id, nu.username, nu.display_name, nu.tier,
             nw.balance_minor, nw.currency, nw.is_test
      FROM nu, nw
    '''),
    parameters: {
      'u': username,
      'ulc': username.toLowerCase(),
      'ph': hash,
      't': token,
      'start': startCredits,
    },
  );

  return ok({'token': token, ...profileJson(res.first.toColumnMap())},
      status: 201);
}
