// Lokaler Speicher der platzierten Wetten ("My Bets") inkl. Fortschritt.
// MVP: rein im Arbeitsspeicher (kein Backend). Fortschritt kommt jetzt aus
// AUFGENOMMENEN Laeufen (Recorder): ein qualifizierter Lauf = eine Aktivitaet
// (frueher der „Aktivitaet simulieren"-Zaehler). ChangeNotifier -> UI aktualisiert sich.

import 'package:flutter/foundation.dart';

import '../models/bet.dart';
import '../models/run.dart';

/// Eine platzierte Wette samt Fortschritt und aufgenommenen Laeufen.
class PlacedBet {
  PlacedBet(this.bet);

  final Bet bet;
  int activitiesDone = 0;

  /// Aufgenommene Laeufe (je ein Buendel roher Punkte). Bleiben erhalten —
  /// spaeter urteilt der Server ueber sie; heute lokaler MVP-Stand.
  final List<Run> runs = [];

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

  /// Ist der Nutzer dieser (konkreten) Wette schon beigetreten?
  /// Prueft die Identitaet der Wett-Instanz: Die `sampleBets`-Liste wird EINMAL
  /// gebaut, jede Beispiel-Wette ist also eine stabile Einzel-Instanz — damit
  /// erkennt `identical` einen erneuten Beitritt zuverlaessig.
  /// (Spaeter, mit echten Server-IDs, wird hier ueber die Wett-ID verglichen.)
  bool hasJoined(Bet bet) => _bets.any((pb) => identical(pb.bet, bet));

  void add(Bet bet) {
    _bets.insert(0, PlacedBet(bet)); // neueste zuerst
    notifyListeners();
  }

  /// Einen aufgenommenen Lauf verbuchen. `qualifies` = Zieldistanz im geforderten
  /// Tempo-Typ erreicht -> eine Aktivitaet gutschreiben. Der Lauf wird IMMER als
  /// Roh-Buendel behalten (spaetere Server-Pruefung).
  void recordRun(PlacedBet pb, Run run, {required bool qualifies}) {
    pb.runs.add(run);
    if (qualifies && !pb.isComplete) pb.activitiesDone++;
    notifyListeners();
  }
}

/// Globale Instanz fuer den MVP (spaeter durch echte Persistenz/Backend ersetzt).
final myBetsStore = MyBetsStore();
