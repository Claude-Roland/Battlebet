// Lokale Beispieldaten fuer den ersten Durchstich (noch kein Backend).
// MVP-Fokus: NUR Joggen.
//
// Jede Wette hat einen Pot-TYP (`tier`), der Deckel und Zugang bestimmt:
//   Limited (Bronze, offen fuer alle) · Limited large (ab Silber) · Unlimited (Obsidian).
// Der Deckel kommt aus dem Typ (500 / 2000 / kein); `starters` bleiben darunter,
// GetAll ist absichtlich VOLL. Meist EUR, adidas USD. Als Anfaenger (Bronze) sind
// die Silber-/Obsidian-Pots in der Liste ausgegraut — als Anreiz.

import '../models/bet.dart';
import '../models/money.dart';
import '../models/tiers.dart';

final sampleBets = <Bet>[
  Bet(
    name: 'Dominator', sport: Sport.jogging, distanceKm: 7, iterationsPerWeek: 2, expirationDays: 10,
    stake: Money.of(10, 'EUR'), tier: PotTier.limited, starters: 38, dropouts: 8,
  ),
  Bet(
    name: 'Tribun 11', sport: Sport.jogging, distanceKm: 7.5, iterationsPerWeek: 3, expirationDays: 303,
    stake: Money.of(45, 'EUR'), tier: PotTier.limitedLarge, starters: 30, dropouts: 18,
  ),
  Bet(
    name: 'GetAll', sport: Sport.jogging, distanceKm: 7, iterationsPerWeek: 4, expirationDays: 12,
    stake: Money.of(20, 'EUR'), tier: PotTier.limited, starters: 25, dropouts: 12, // 25 = max -> VOLL
  ),
  Bet(
    name: 'adidas Summerrun', sport: Sport.jogging, distanceKm: 8, iterationsPerWeek: 1, expirationDays: 126,
    stake: Money.of(1, 'USD'), tier: PotTier.limited, starters: 320, dropouts: 300, tag: BetTag.sponsored,
  ),
  Bet(
    name: 'UniversityRun19', sport: Sport.jogging, distanceKm: 198.5, iterationsPerWeek: 2, expirationDays: 23,
    stake: Money.of(50, 'EUR'), tier: PotTier.unlimited, starters: 100, dropouts: 88, // Unlimited: nie "voll"
  ),
  Bet(
    name: 'RunRunRun', sport: Sport.jogging, distanceKm: 9, iterationsPerWeek: 7, expirationDays: 356,
    stake: Money.of(30, 'EUR'), tier: PotTier.limitedLarge, starters: 45, dropouts: 6,
  ),
  Bet(
    name: 'Bellymelters', sport: Sport.jogging, distanceKm: 14, iterationsPerWeek: 2, expirationDays: 165,
    stake: Money.of(80, 'EUR'), tier: PotTier.limitedLarge, starters: 20, dropouts: 7,
  ),
];
