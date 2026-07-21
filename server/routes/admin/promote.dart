import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/db.dart';

/// Bootstrap: ein Konto zum Personal machen (is_staff = true) bzw. zuruecksetzen.
/// Geschuetzt durch den ADMIN_TOKEN (Header X-Admin-Token) — kein DB-Zugriff noetig.
/// Body: { "username": "...", "staff": true }  (staff optional, Standard true).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final token = context.request.headers['x-admin-token'];
  final expected = Platform.environment['ADMIN_TOKEN'] ?? 'dev-tick';
  if (token != expected) return fail('Forbidden.', status: 403);

  final body = await readJson(context);
  final username = (body['username'] as String?)?.trim() ?? '';
  final staff = (body['staff'] as bool?) ?? true;
  if (username.isEmpty) return fail('username required.');

  final res = await db.execute(
    Sql.named('''
      UPDATE users SET is_staff = @s
      WHERE username_lc = @u
      RETURNING username, is_staff
    '''),
    parameters: {'s': staff, 'u': username.toLowerCase()},
  );
  if (res.isEmpty) return fail('No account with this username.', status: 404);
  final r = res.first.toColumnMap();
  return ok({'username': r['username'], 'isStaff': r['is_staff']});
}
