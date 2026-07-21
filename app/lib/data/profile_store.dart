// Profil-Daten (Guthaben in Test-Credits, Anzeigename, Bet-Tier) — Server = Wahrheit.
// Wird nach Login/Registrierung mit dem Server-Profil gefuellt; Ein-/Auszahlen und
// Namensaenderung laufen ueber den Server. Test-Credits, bis die echte Geld-Schicht
// kommt (dann nur ein Austausch der Datenquelle, kein Umbau).

import 'package:flutter/foundation.dart';

import '../models/money.dart';
import 'api_client.dart';

class ProfileStore extends ChangeNotifier {
  Money _balance = const Money(0, 'EUR');
  String _name = ''; // Anzeigename; leer -> Login-Name verwenden
  int _tier = 0;
  String _tierLabel = 'Bet Tier 1';
  bool _isTest = true;

  Money get balance => _balance;
  String get customName => _name;
  int get tier => _tier;
  String get tierLabel => _tierLabel;
  bool get isTest => _isTest;

  /// Anzeigename mit Rueckfall auf den Login-Namen.
  String displayName(String fallback) =>
      _name.trim().isEmpty ? fallback : _name.trim();

  /// Uebernimmt ein frisches Server-Profil.
  void applyProfile(Profile p) {
    _balance = p.balance;
    _name = p.displayName == p.username ? '' : p.displayName;
    _tier = p.tier;
    _tierLabel = p.tierLabel;
    _isTest = p.walletIsTest;
    notifyListeners();
  }

  /// Zuruecksetzen beim Abmelden.
  void clear() {
    _balance = const Money(0, 'EUR');
    _name = '';
    _tier = 0;
    _tierLabel = 'Bet Tier 1';
    _isTest = true;
    notifyListeners();
  }

  /// Anzeigename setzen (Server), dann lokal uebernehmen.
  Future<String?> setName(String name) async {
    try {
      applyProfile(await api.setDisplayName(name.trim()));
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not save the name.';
    }
  }

  /// Einzahlen (ganze Waehrungseinheiten -> Cent) via Server.
  Future<String?> deposit(int amountMajor) async {
    if (amountMajor <= 0) return null;
    try {
      _balance = await api.deposit(amountMajor * 100);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Deposit failed.';
    }
  }

  /// Auszahlen (ganze Waehrungseinheiten -> Cent) via Server.
  Future<String?> withdraw(int amountMajor) async {
    if (amountMajor <= 0) return null;
    try {
      _balance = await api.withdraw(amountMajor * 100);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Withdrawal failed.';
    }
  }
}

/// Globale Instanz.
final profileStore = ProfileStore();
