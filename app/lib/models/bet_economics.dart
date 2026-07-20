// BetEconomics — die echte Wett-Oekonomie eines Pots.
// Grundlage: die ENTSCHIEDENE Oekonomie (Memory „wett-oekonomie", Roland 2026-07-20).
//
// KERN-VERSPRECHEN: WER SEIN PENSUM DURCHHAELT, VERLIERT NIE GELD.
//
// So funktioniert der Pot (Roland-Regeln):
//   • Viele Einsaetze fliessen in EINEN Topf (Pot). Eine Wette = eine Waehrung.
//   • Wer aussteigt, VERLIERT seinen Einsatz — dieses „Aussteiger-Geld" bleibt im
//     Topf und erhoeht den Gewinn der Durchhalter.
//   • Die Plattform-FEE ist 10 % — aber NUR vom AUSSTEIGER-GELD, nicht vom ganzen
//     Topf. Steigt niemand aus, faellt KEINE Fee an, und jeder bekommt exakt seinen
//     Einsatz zurueck (die Plattform verdient dann nichts).
//   • Jeder Durchhalter bekommt seinen EIGENEN Einsatz zurueck + einen gleichen
//     Anteil am (Aussteiger-Geld − Fee).
//   • „increase in value" wird daraus ABGELEITET — und ist immer >= 0.
//   • DECKEL = feste Topf-Hoehe (potCap) aus dem Pot-Typ -> Hoechst-Teilnehmerzahl;
//     ist der Topf voll, nimmt er niemanden mehr auf. UNLIMITED (Bet Tier 3):
//     potCap = null -> kein Deckel, nie „voll".

import 'money.dart';

class BetEconomics {
  /// Einsatz je Teilnehmer (fix bei Erstellung).
  final Money stake;

  /// Fester Topf-Deckel; null = unbegrenzt (Bet Tier 3 / Unlimited).
  final Money? potCap;

  /// Plattform-Fee in Basispunkten: 1000 = 10 % (vom Aussteiger-Geld).
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

  /// Durchhalter (mindestens 1, um Division durch 0 zu vermeiden).
  int get finishers {
    final f = starters - dropouts;
    return f < 1 ? 1 : f;
  }

  /// Aktueller Topf = Einsatz × Starter (alle Einsaetze, auch die der Aussteiger).
  Money get pot => stake * starters;

  /// Aussteiger-Geld = verfallene Einsaetze = Einsatz × Aussteiger.
  Money get forfeited => stake * dropouts;

  /// Plattform-Fee = feeBps vom AUSSTEIGER-GELD (nicht vom ganzen Topf).
  /// Steigt niemand aus (forfeited = 0), ist die Fee 0.
  Money get fee => forfeited.scale(feeBps / 10000);

  /// Aussteiger-Geld nach Fee — der Ueberschuss, der auf die Durchhalter verteilt wird.
  Money get surplus => Money(forfeited.minor - fee.minor, stake.currency);

  /// Was insgesamt an die Durchhalter geht = Topf − Fee (die Fee ist die einzige Abgabe).
  Money get distributable => Money(pot.minor - fee.minor, stake.currency);

  /// Anteil am Ueberschuss je Durchhalter (Rest verfaellt cent-genau).
  Money get surplusPerFinisher => surplus.dividedBy(finishers);

  /// Auszahlung je Durchhalter = eigener Einsatz + Anteil am Ueberschuss.
  /// Ist damit IMMER >= Einsatz — ein Durchhalter verliert nie.
  Money get payoutPerFinisher =>
      Money(stake.minor + surplusPerFinisher.minor, stake.currency);

  /// Wertsteigerung je Durchhalter in Prozent (abgeleitet, immer >= 0).
  double get increasePct =>
      stake.minor == 0 ? 0 : (payoutPerFinisher.minor / stake.minor - 1) * 100;

  /// Ganzzahlige Prozentanzeige (kaufmaennisch gerundet), z. B. „+24%".
  int get increasePctRounded => increasePct.round();
}
