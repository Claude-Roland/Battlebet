import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  final token = bearer(context)!;
  final body = await readJson(context);
  final amount = (body['amountMinor'] as num?)?.toInt() ?? 0;
  if (amount <= 0) return fail('Amount must be positive.');

  final res = await db.execute(
    Sql.named('''
      WITH s AS (
        SELECT user_id FROM sessions WHERE token = @t AND expires_at > now()
      ), upd AS (
        UPDATE wallets w
        SET balance_minor = balance_minor - @amt, updated_at = now()
        FROM s WHERE w.user_id = s.user_id AND w.currency = 'EUR'
          AND w.balance_minor >= @amt
        RETURNING w.user_id, w.balance_minor, w.currency, w.is_test
      ), led AS (
        INSERT INTO ledger (user_id, kind, amount_minor, currency,
                            balance_after_minor, note)
        SELECT user_id, 1, -@amt, currency, balance_minor,
               'withdraw (test credits)' FROM upd
      )
      SELECT balance_minor, currency, is_test FROM upd
    '''),
    parameters: {'t': token, 'amt': amount},
  );
  if (res.isEmpty) return fail('Insufficient balance.', status: 409);
  return ok({'wallet': walletJson(res.first.toColumnMap())});
}
