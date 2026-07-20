// Der aktuelle Nutzer (MVP: nur die Vertrauensstufe, simuliert).
// Spaeter ein echtes serverseitiges Konto, dessen Stufe man sich durch saubere
// Historie VERDIENT. Heute ist die Stufe frei umschaltbar — ueber den kleinen
// Vorschau-Chip in der TopNav (`science`-Symbol) — damit man im laufenden
// Programm sieht, wie sich Ausgrauen/Freigeben aendert. Der Chip ist ein
// Entwickler-/Vorschau-Hilfsmittel und faellt spaeter weg.

import 'package:flutter/foundation.dart';

import '../models/tiers.dart';

class UserSession extends ChangeNotifier {
  UserTier _tier = UserTier.bronze; // Start als Anfaenger

  UserTier get tier => _tier;

  set tier(UserTier value) {
    if (value == _tier) return;
    _tier = value;
    notifyListeners();
  }

  /// Schaltet zur naechsten Stufe weiter (Bronze -> Silber -> Obsidian -> Bronze).
  void cycle() => tier = UserTier.values[(_tier.index + 1) % UserTier.values.length];
}

/// Globale Instanz fuer den MVP (spaeter durch echtes Konto ersetzt).
final userSession = UserSession();
