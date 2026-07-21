// Merkt das Sitzungs-Token lokal ("dieses Geraet fuer 30 Tage merken").
// Auf dem Web nutzt shared_preferences den Browser-Speicher. Wir speichern das
// Token plus ein Ablaufdatum; beim Start wird bei gueltigem Merker automatisch
// angemeldet. Ohne Merker bleibt das Token nur im Arbeitsspeicher (Abmelden beim Neuladen).

import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _kToken = 'bb_token';
  static const _kExpiry = 'bb_token_expiry';

  /// Token merken (Standard: 30 Tage).
  Future<void> save(String token, {Duration ttl = const Duration(days: 30)}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setInt(_kExpiry, DateTime.now().add(ttl).millisecondsSinceEpoch);
  }

  /// Gemerktes Token laden (oder null, wenn keins/abgelaufen).
  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final expiry = prefs.getInt(_kExpiry);
    if (token == null || expiry == null) return null;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      await clear();
      return null;
    }
    return token;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kExpiry);
  }
}

final sessionStore = SessionStore();
