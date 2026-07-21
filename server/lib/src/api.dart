import 'dart:convert';
import 'dart:math';

import 'package:battlebet_server/src/db.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// JSON-Erfolgsantwort.
Response ok(Object? data, {int status = 200}) =>
    Response.json(statusCode: status, body: data);

/// JSON-Fehlerantwort.
Response fail(String message, {int status = 400}) =>
    Response.json(statusCode: status, body: {'error': message});

/// Liest den Request-Body als JSON-Map (leere Map bei Fehler/leer).
Future<Map<String, dynamic>> readJson(RequestContext context) async {
  try {
    final body = await context.request.body();
    if (body.trim().isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {};
  } catch (_) {
    return {};
  }
}

/// Passwort sicher hashen (bcrypt).
String hashPassword(String plain) => BCrypt.hashpw(plain, BCrypt.gensalt());

/// Passwort gegen den gespeicherten Hash pruefen.
bool checkPassword(String plain, String hash) {
  try {
    return BCrypt.checkpw(plain, hash);
  } catch (_) {
    return false;
  }
}

final _rng = Random.secure();

/// Neues, zufaelliges Sitzungs-Token (opak, 256 Bit).
String newToken() {
  final bytes = List<int>.generate(32, (_) => _rng.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Bearer-Token aus dem Authorization-Header (oder null).
String? bearer(RequestContext context) {
  final header = context.request.headers['authorization'];
  if (header == null) return null;
  final parts = header.split(' ');
  if (parts.length != 2 || parts[0].toLowerCase() != 'bearer') return null;
  final token = parts[1].trim();
  return token.isEmpty ? null : token;
}

/// Der angemeldete Nutzer inkl. Wallet (oder null bei ungueltigem Token).
Future<Map<String, dynamic>?> authed(RequestContext context) async {
  final token = bearer(context);
  if (token == null) return null;
  final res = await db.execute(
    Sql.named('''
      SELECT u.id, u.username, u.display_name, u.tier, u.is_staff,
             w.balance_minor, w.currency, w.is_test
      FROM sessions s
      JOIN users u ON u.id = s.user_id
      JOIN wallets w ON w.user_id = u.id AND w.currency = 'EUR'
      WHERE s.token = @t AND s.expires_at > now()
    '''),
    parameters: {'t': token},
  );
  if (res.isEmpty) return null;
  return res.first.toColumnMap();
}

/// Wie [authed], aber nur fuer Personal (is_staff = true). Sonst null.
Future<Map<String, dynamic>?> authedStaff(RequestContext context) async {
  final me = await authed(context);
  if (me == null) return null;
  final staff = (me['is_staff'] as bool?) ?? false;
  return staff ? me : null;
}

const _tierLabels = ['Bet Tier 1', 'Bet Tier 2', 'Bet Tier 3'];

/// Anzeige-Label einer Bet-Tier-Stufe.
String tierLabel(int tier) => _tierLabels[tier < 0 ? 0 : (tier > 2 ? 2 : tier)];

String _displayName(Map<String, dynamic> row) {
  final custom = (row['display_name'] as String?)?.trim() ?? '';
  return custom.isEmpty ? (row['username'] as String) : custom;
}

/// Baut die Profil-JSON (Nutzer + Wallet) aus einer kombinierten Zeile.
Map<String, dynamic> profileJson(Map<String, dynamic> row) => {
      'user': {
        'id': row['id'].toString(),
        'username': row['username'],
        'displayName': _displayName(row),
        'tier': (row['tier'] as num).toInt(),
        'tierLabel': tierLabel((row['tier'] as num).toInt()),
        'isStaff': (row['is_staff'] as bool?) ?? false,
      },
      'wallet': walletJson(row),
    };

/// Nur die Wallet-JSON (fuer Ein-/Auszahlungen).
Map<String, dynamic> walletJson(Map<String, dynamic> row) => {
      'balanceMinor': (row['balance_minor'] as num).toInt(),
      'currency': (row['currency'] as String).trim(),
      'isTest': row['is_test'],
    };
