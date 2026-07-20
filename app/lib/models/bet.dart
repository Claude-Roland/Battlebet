// Datenmodell einer Wette (Katalog-Entitaet `Bet`, MVP-Felder).
// Geld laeuft ueber den `Money`-Typ (Cent + Waehrung); die Pot-Zahlen
// (pot, payout, "increase in value", Teilnehmer-Deckel) werden NICHT gespeichert,
// sondern von `BetEconomics` aus wenigen echten Feldern GERECHNET.
// Felder fuer spaetere Stufen (Sponsoren-Details, SOCKS, Batches ...) sind
// bewusst noch NICHT hier -> Grundsatz "architektonisch offen, funktional minimal".

import 'bet_economics.dart';
import 'money.dart';

/// Sportart einer Wette. Bestimmt Anzeige-Label und (spaeter) Icon-Asset.
enum Sport {
  jogging,
  running,
  skating,
  offRoadBiking,
  crossCountrySkiing;

  /// Anzeige-Text der Sportart (wie im Entwurf).
  String get label => switch (this) {
        Sport.jogging => 'jogging',
        Sport.running => 'running',
        Sport.skating => 'skating',
        Sport.offRoadBiking => 'off-road biking',
        Sport.crossCountrySkiing => 'cross country skiing',
      };
}

/// Optionale Markierung einer Wette in der Liste.
enum BetTag { none, isNew, sponsored, special }

/// Pruefprofil (Sicherheits-/Pruefstufe) eines Pots — SAMEN fuer die spaetere
/// Staffelung (Zielarchitektur 6.4 + 8). HEUTE gibt es nur EINE Stufe
/// (`standard` = die Bronze-/Basis-Sprosse): eine solide Standard-Pruefung +
/// harter Topf-Deckel. Die Leiter Bronze → Silber → Obsidian (steigende Deckel
/// bis hin zum praktisch offenen Topf der obersten, nur von Personal anlegbaren
/// Stufe) ist bewusst zurueckgestellt. Wird sie gebaut, kommen die weiteren
/// Werte hier dazu — das Feld ist schon da, es gibt keinen Umbau.
enum CheckProfile { standard }

/// Eine Wette, wie sie in der Bets-Liste erscheint.
/// Der wirtschaftliche Teil ist ein "typisierter Vertrag", bei Erstellung fixiert:
/// Einsatz (`stake`), Topf-Deckel (`potCap`) und Fee (`feeBps`) aendern sich nie.
/// `starters`/`dropouts` sind der (im MVP simulierte) Pool-Zustand.
class Bet {
  const Bet({
    required this.name,
    required this.sport,
    required this.distanceKm,
    required this.iterationsPerWeek,
    required this.expirationDays,
    required this.stake,
    required this.potCap,
    this.feeBps = 1000, // 10 % Standard-Fee
    this.checkProfile = CheckProfile.standard, // heute immer die eine Stufe
    this.starters = 1, // frisch angelegt: nur der Ersteller
    this.dropouts = 0,
    this.tag = BetTag.none,
    this.bookmarked = false,
  });

  final String name;
  final Sport sport;
  final double distanceKm; // "7km"
  final int iterationsPerWeek; // "2 x w"
  final int expirationDays; // "10d"

  // --- Wirtschaftlicher Vertrag (fix bei Erstellung) ---
  final Money stake; // Einsatz je Teilnehmer
  final Money potCap; // feste Topf-Obergrenze (begrenzt Teilnehmer + Gewinn)
  final int feeBps; // Plattform-Fee in Basispunkten (1000 = 10 %)
  final CheckProfile checkProfile; // Pruef-/Sicherheitsstufe (heute: standard)

  // --- Pool-Zustand (im MVP simuliert; spaeter vom Server) ---
  final int starters; // wie viele insgesamt eingezahlt haben
  final int dropouts; // wie viele davon ausgestiegen sind

  final BetTag tag;
  final bool bookmarked;

  /// Rechnet die echten Pot-Zahlen (pot, payout, increase, Deckel) aus den Feldern.
  BetEconomics get economics => BetEconomics(
        stake: stake,
        potCap: potCap,
        feeBps: feeBps,
        starters: starters,
        dropouts: dropouts,
      );
}
