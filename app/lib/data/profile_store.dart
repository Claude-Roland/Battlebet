// Profil-Daten des Nutzers (MVP: simuliert, rein im Arbeitsspeicher).
//
// - GUTHABEN (Wallet): kann ein- und ausgezahlt werden. HEUTE SIMULIERT — echtes
//   Geld kommt mit dem Server (regulierter Bereich). Der Wechsel ist nur ein
//   Austausch der Datenquelle, kein Umbau.
// - ANZEIGENAME (Personalisierung): ueberschreibt den Login-Namen fuer die Anzeige.
//
// ChangeNotifier -> die Profil-Seite aktualisiert sich bei jeder Aenderung.

import 'package:flutter/foundation.dart';

import '../models/money.dart';

class ProfileStore extends ChangeNotifier {
  Money _balance = Money.of(100, 'EUR'); // Startguthaben (simuliert)
  String _name = ''; // Anzeigename; leer -> Login-Name verwenden

  Money get balance => _balance;

  /// Frei gewaehlter Anzeigename (leer = keiner gesetzt).
  String get customName => _name;

  /// Anzeigename mit Rueckfall auf den Login-Namen.
  String displayName(String fallback) => _name.trim().isEmpty ? fallback : _name.trim();

  void setName(String name) {
    _name = name.trim();
    notifyListeners();
  }

  /// Einzahlen (simuliert): ganze Waehrungseinheiten draufbuchen.
  void deposit(int amount) {
    if (amount <= 0) return;
    _balance = Money(_balance.minor + amount * 100, _balance.currency);
    notifyListeners();
  }

  /// Auszahlen (simuliert): abbuchen, nie unter 0.
  void withdraw(int amount) {
    if (amount <= 0) return;
    final m = _balance.minor - amount * 100;
    _balance = Money(m < 0 ? 0 : m, _balance.currency);
    notifyListeners();
  }
}

/// Globale Instanz fuer den MVP (spaeter durch echtes Konto/Server ersetzt).
final profileStore = ProfileStore();
