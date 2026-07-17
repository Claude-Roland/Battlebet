// Einfache Anmeldung/Registrierung (Katalog-Entität `User`).
// MVP: rein im Arbeitsspeicher (kein Backend, keine Persistenz, kein Hashing —
// kommt später). Hält die registrierten Nutzer und den aktuell angemeldeten.

import 'package:flutter/foundation.dart';

class AuthStore extends ChangeNotifier {
  final Map<String, String> _users = {}; // username -> passwort (MVP-Platzhalter)
  String? _currentUser;

  String? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Registriert einen neuen Nutzer. Rückgabe: Fehlermeldung oder null bei Erfolg.
  String? register(String username, String password) {
    final u = username.trim();
    if (u.isEmpty || password.isEmpty) return 'Bitte Username und Passwort eingeben.';
    if (_users.containsKey(u)) return 'Dieser Username ist schon vergeben.';
    _users[u] = password;
    _currentUser = u;
    notifyListeners();
    return null;
  }

  /// Meldet einen Nutzer an. Rückgabe: Fehlermeldung oder null bei Erfolg.
  String? login(String username, String password) {
    final u = username.trim();
    if (u.isEmpty || password.isEmpty) return 'Bitte Username und Passwort eingeben.';
    if (!_users.containsKey(u)) return 'Kein Konto mit diesem Username.';
    if (_users[u] != password) return 'Passwort stimmt nicht.';
    _currentUser = u;
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

/// Globale Instanz für den MVP (später durch echte Auth/Backend ersetzt).
final authStore = AuthStore();
