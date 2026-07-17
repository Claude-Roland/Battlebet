// Lokaler Speicher der platzierten Wetten ("My Bets") inkl. Fortschritt.
// MVP: rein im Arbeitsspeicher (kein Backend), Aktivitaeten werden SIMULIERT
// (Ersatz fuer echtes GPS-Tracking). ChangeNotifier -> UI aktualisiert sich.

import 'package:flutter/foundation.dart';

import '../models/bet.dart';

/// Eine platzierte Wette samt Fortschritt.
class PlacedBet {
  PlacedBet(this.bet);

  final Bet bet;
  int activitiesDone = 0;

  /// Gesamt benoetigte Aktivitaeten = Haeufigkeit/Woche × Wochen.
  int get totalActivities {
    final weeks = (bet.expirationDays / 7).round();
    final total = bet.iterationsPerWeek * weeks;
    return total < 1 ? 1 : total;
  }

  double get progress => (activitiesDone / totalActivities).clamp(0.0, 1.0);
  bool get isComplete => activitiesDone >= totalActivities;
}

class MyBetsStore extends ChangeNotifier {
  final List<PlacedBet> _bets = [];

  List<PlacedBet> get bets => List.unmodifiable(_bets);

  void add(Bet bet) {
    _bets.insert(0, PlacedBet(bet)); // neueste zuerst
    notifyListeners();
  }

  /// Simuliert eine absolvierte Aktivitaet (MVP-Ersatz fuer echtes GPS-Tracking).
  void simulateActivity(PlacedBet pb) {
    if (pb.isComplete) return;
    pb.activitiesDone++;
    notifyListeners();
  }
}

/// Globale Instanz fuer den MVP (spaeter durch echte Persistenz/Backend ersetzt).
final myBetsStore = MyBetsStore();
