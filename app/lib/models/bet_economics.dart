// BetEconomics — die echte Wett-Oekonomie eines Pots (ersetzt die Platzhalter).
// Grundlage: Rahmenbedingungen_und_Zielarchitektur.md, Abschnitt 8 (Pot-Oekonomie).
//
// So funktioniert der Pot (Roland-Regeln):
//   • Viele Einsaetze fliessen in EINEN Topf (Pot).  Eine Wette = eine Waehrung.
//   • Wer aussteigt, VERLIERT seinen Einsatz — das Geld bleibt im Topf und
//     erhoeht den Gewinn der Durchhalter.
//   • Die Plattform nimmt eine FEE vom Topf (Standard 10 %).
//   • Was uebrig bleibt, teilen sich die DURCHHALTER (finishers) zu gleichen Teilen.
//   • "increase in value" wird daraus ABGELEITET (kein Eingabewert).
//   • DECKEL = feste Topf-Hoehe (potCap) aus dem Pot-Typ. Aus Topf-Hoehe ÷ Einsatz
//     ergibt sich die maximale Teilnehmerzahl; ist der Topf voll, nimmt er niemanden
//     mehr auf ("kein heimliches Aufsteigen").
//   • UNLIMITED: potCap = null -> kein Deckel, keine Hoechst-Teilnehmerzahl,
//     nie "voll" (nur fuer Obsidian).

import 'money.dart';

class BetEconomics {
  /// Einsatz je Teilnehmer (fix bei Erstellung).
  final Money stake;

  /// Fester Topf-Deckel; null = unbegrenzt (Unlimited-Pot).
  final Money? potCap;

  /// Plattform-Fee in Basispunkten: 1000 = 10 %.
  final int feeBps;

  /// Wie viele insgesamt eingezahlt haben (Starter). Treibt die Pot-Groesse.
  final int starters;

  /// Wie viele davon inzwischen ausgestiegen sind (Einsatz verfallen).
  final int dropouts;

  const BetEconomics({
    required this.stake,
    required this.potCap,
    required this.feeBps,
    required this.starters,
    required this.dropouts,
  });

  bool get isUnlimited => potCap == null;

  /// Maximale Starterzahl = Topf-Hoehe ÷ Einsatz (abgerundet); null bei unbegrenzt.
  int? get maxStarters =>
      (isUnlimited || stake.minor <= 0) ? null : potCap!.minor ~/ stake.minor;

  /// Topf voll? Nur bei begrenztem Topf moeglich.
  bool get isFull => maxStarters != null && starters >= maxStarters!;

  /// Noch dabei = Durchhalter (mindestens 1, um Division durch 0 zu vermeiden).
  int get finishers {
    final f = starters - dropouts;
    return f < 1 ? 1 : f;
  }

  /// Aktueller Topf = Einsatz × Starter (Aussteiger-Einsaetze bleiben drin).
  Money get pot => stake * starters;

  /// Plattform-Anteil (Fee) am Topf.
  Money get fee => pot.scale(feeBps / 10000);

  /// Was nach Fee an die Durchhalter geht.
  Money get distributable => Money(pot.minor - fee.minor, stake.currency);

  /// Auszahlung je Durchhalter = verteilbarer Topf ÷ Durchhalter.
  Money get payoutPerFinisher => distributable.dividedBy(finishers);

  /// Wertsteigerung je Durchhalter in Prozent (abgeleitet, kann negativ sein).
  double get increasePct =>
      stake.minor == 0 ? 0 : (payoutPerFinisher.minor / stake.minor - 1) * 100;

  /// Ganzzahlige Prozentanzeige (kaufmaennisch gerundet), z. B. "+41%".
  int get increasePctRounded => increasePct.round();
}
