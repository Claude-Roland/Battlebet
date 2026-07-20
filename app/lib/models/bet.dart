// Datenmodell einer Wette (Katalog-Entitaet `Bet`, MVP-Felder).
// Geld laeuft ueber den `Money`-Typ (Cent + Waehrung); die Pot-Zahlen
// (pot, payout, "increase in value", Deckel) werden NICHT gespeichert, sondern
// von `BetEconomics` gerechnet. Der Pot-TYP (`PotTier`) bestimmt Deckel + Zugang.

import 'bet_economics.dart';
import 'money.dart';
import 'tiers.dart';

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

/// Eine Wette. Der wirtschaftliche Teil ist bei Erstellung fixiert:
/// Einsatz (`stake`), Pot-Typ (`tier` -> Deckel + Zugang) und Fee (`feeBps`).
/// `starters`/`dropouts` sind der (im MVP simulierte) Pool-Zustand.
class Bet {
  const Bet({
    required this.name,
    required this.sport,
    required this.distanceKm,
    required this.iterationsPerWeek,
    required this.expirationDays,
    required this.stake,
    this.tier = PotTier.limited, // Standard: der fuer alle offene Limited-Pot
    this.feeBps = 1000, // 10 % Standard-Fee
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
  final PotTier tier; // Pot-Typ: Deckel-Hoehe + wer eroeffnen/beitreten darf
  final int feeBps; // Plattform-Fee in Basispunkten (1000 = 10 %)

  // --- Pool-Zustand (im MVP simuliert; spaeter vom Server) ---
  final int starters; // wie viele insgesamt eingezahlt haben
  final int dropouts; // wie viele davon ausgestiegen sind

  final BetTag tag;
  final bool bookmarked;

  /// Fester Topf-Deckel aus dem Pot-Typ (null = unbegrenzt).
  Money? get potCap => tier.capIn(stake.currency);

  /// Rechnet die echten Pot-Zahlen (pot, payout, increase, Deckel) aus den Feldern.
  BetEconomics get economics => BetEconomics(
        stake: stake,
        potCap: potCap,
        feeBps: feeBps,
        starters: starters,
        dropouts: dropouts,
      );
}
