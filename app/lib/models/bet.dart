// Datenmodell einer Wette (Katalog-Entitaet `Bet`, MVP-Felder).
// Felder fuer spaetere Stufen (Sponsoren-Details, SOCKS, Batches ...) sind
// bewusst noch NICHT hier -> Grundsatz "architektonisch offen, funktional minimal".

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

/// Eine Wette, wie sie in der Bets-Liste erscheint.
/// (MVP: reine Anzeige-Daten aus lokalen Beispieldaten.)
class Bet {
  const Bet({
    required this.name,
    required this.sport,
    required this.distanceKm,
    required this.iterationsPerWeek,
    required this.expirationDays,
    required this.entryPrice,
    required this.increaseInValuePct,
    this.tag = BetTag.none,
    this.bookmarked = false,
  });

  final String name;
  final Sport sport;
  final double distanceKm; // "7km"
  final int iterationsPerWeek; // "2 x w"
  final int expirationDays; // "10d"
  final double entryPrice; // "12.50$"
  final int increaseInValuePct; // "5%"
  final BetTag tag;
  final bool bookmarked;
}
