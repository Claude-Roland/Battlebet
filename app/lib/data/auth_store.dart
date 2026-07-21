// Server-gestuetzte Anmeldung/Registrierung (echte Konten).
// Ersetzt den frueheren lokalen Platzhalter; das Token haelt der ApiClient.
// Nach Erfolg wird das Server-Profil in den profileStore uebernommen.

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'profile_store.dart';

class AuthStore extends ChangeNotifier {
  String? _currentUser;

  String? get currentUser => _currentUser;
  bool get isLoggedIn => api.isLoggedIn;

  /// Registriert. Rueckgabe: Fehlermeldung oder null bei Erfolg.
  Future<String?> register(String username, String password) =>
      _run(() => api.register(username.trim(), password));

  /// Meldet an. Rueckgabe: Fehlermeldung oder null bei Erfolg.
  Future<String?> login(String username, String password) =>
      _run(() => api.login(username.trim(), password));

  Future<String?> _run(Future<AuthResult> Function() action) async {
    try {
      final result = await action();
      _currentUser = result.profile.username;
      profileStore.applyProfile(result.profile);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unexpected error. Please try again.';
    }
  }

  void logout() {
    api.logout();
    _currentUser = null;
    profileStore.clear();
    notifyListeners();
  }
}

/// Globale Instanz.
final authStore = AuthStore();
