// HTTP-Client zum BattleBet-Server (echte Konten, Wallet in Test-Credits).
// Haelt das Sitzungs-Token im Speicher. Basis-URL per --dart-define ueberschreibbar
// (BB_API), Standard = lokaler Dart-Frog-Dev-Server.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bet.dart';
import '../models/money.dart';

/// Basis-URL des Servers. Lokal: der Dart-Frog-Dev-Server auf Port 8081.
const String kApiBaseUrl =
    String.fromEnvironment('BB_API', defaultValue: 'http://localhost:8081');

/// Fehler mit nutzerlesbarer Meldung (vom Server oder Client).
class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Profil-Sicht des angemeldeten Nutzers (Server = Wahrheit).
class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.tier,
    required this.tierLabel,
    required this.balance,
    required this.walletIsTest,
  });

  factory Profile.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>;
    final wallet = j['wallet'] as Map<String, dynamic>;
    return Profile(
      id: user['id'] as String,
      username: user['username'] as String,
      displayName: user['displayName'] as String,
      tier: (user['tier'] as num).toInt(),
      tierLabel: user['tierLabel'] as String,
      balance: Money(
        (wallet['balanceMinor'] as num).toInt(),
        wallet['currency'] as String,
      ),
      walletIsTest: wallet['isTest'] as bool? ?? true,
    );
  }

  final String id;
  final String username;
  final String displayName;
  final int tier;
  final String tierLabel;
  final Money balance;
  final bool walletIsTest;
}

/// Ergebnis von Registrierung/Login: Token + Profil.
class AuthResult {
  AuthResult(this.token, this.profile);
  final String token;
  final Profile profile;
}

/// Kleiner Client zum BattleBet-Server. Haelt das Sitzungs-Token.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? token;

  bool get isLoggedIn => token != null;

  Uri _u(String path) => Uri.parse('$kApiBaseUrl$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final http.Response res;
    try {
      res = await _client.post(
        _u(path),
        headers: _headers,
        body: jsonEncode(body),
      );
    } catch (_) {
      throw ApiException('Cannot reach the server. Is it running?');
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final http.Response res;
    try {
      res = await _client.get(_u(path), headers: _headers);
    } catch (_) {
      throw ApiException('Cannot reach the server. Is it running?');
    }
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        (data['error'] as String?) ?? 'Something went wrong (${res.statusCode}).',
      );
    }
    return data;
  }

  Future<AuthResult> register(String username, String password) async {
    final d = await _post('/auth/register', {
      'username': username,
      'password': password,
    });
    token = d['token'] as String;
    return AuthResult(token!, Profile.fromJson(d));
  }

  Future<AuthResult> login(String username, String password) async {
    final d = await _post('/auth/login', {
      'username': username,
      'password': password,
    });
    token = d['token'] as String;
    return AuthResult(token!, Profile.fromJson(d));
  }

  Future<Profile> me() async => Profile.fromJson(await _get('/me'));

  Future<Profile> setDisplayName(String name) async {
    await _post('/me/display-name', {'displayName': name});
    return me(); // frisches Profil (User + Wallet) konsistent zurueckgeben
  }

  Future<Money> deposit(int amountMinor) async {
    final d = await _post('/wallet/deposit', {'amountMinor': amountMinor});
    final w = d['wallet'] as Map<String, dynamic>;
    return Money((w['balanceMinor'] as num).toInt(), w['currency'] as String);
  }

  Future<Money> withdraw(int amountMinor) async {
    final d = await _post('/wallet/withdraw', {'amountMinor': amountMinor});
    final w = d['wallet'] as Map<String, dynamic>;
    return Money((w['balanceMinor'] as num).toInt(), w['currency'] as String);
  }

  /// Alle Wetten vom Server (mit Oekonomie, joined-Markierung).
  Future<List<Bet>> listBets() async {
    final d = await _get('/bets');
    final list = (d['bets'] as List?) ?? const [];
    return list.map((e) => Bet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bet> getBet(String id) async => Bet.fromJson(await _get('/bets/$id'));

  Future<Bet> createBet({
    required String name,
    required int sport,
    required double distanceKm,
    required int iterationsPerWeek,
    required int expirationDays,
    required int stakeMinor,
    required String currency,
    required int tier,
  }) async {
    final d = await _post('/bets', {
      'name': name,
      'sport': sport,
      'distanceKm': distanceKm,
      'iterationsPerWeek': iterationsPerWeek,
      'expirationDays': expirationDays,
      'stakeMinor': stakeMinor,
      'currency': currency,
      'tier': tier,
    });
    return Bet.fromJson(d);
  }

  Future<Bet> joinBet(String id) async => Bet.fromJson(await _post('/bets/$id/join', {}));

  Future<Bet> toggleBookmark(String id) async =>
      Bet.fromJson(await _post('/bets/$id/bookmark', {}));

  /// Einen (eigenstaendigen) Lauf aufnehmen; der Server ordnet ihn passenden Wetten zu.
  Future<Map<String, dynamic>> recordRun({
    required int sport,
    required int source,
    required int totalMeters,
    required int totalSeconds,
    required int avgPace,
  }) async {
    return _post('/runs', {
      'sport': sport,
      'source': source,
      'totalMeters': totalMeters,
      'totalSeconds': totalSeconds,
      'avgPace': avgPace,
    });
  }

  void logout() => token = null;
}

/// Globale Instanz.
final api = ApiClient();
