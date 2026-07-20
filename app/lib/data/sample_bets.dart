// Lokale Beispieldaten fuer den ersten Durchstich (noch kein Backend).
// MVP-Fokus: NUR Joggen. Andere Sportarten kommen spaeter (Modell kann sie schon).
//
// Jede Wette traegt jetzt ihren wirtschaftlichen Vertrag:
//   stake   = Einsatz je Teilnehmer (Money: Cent + Waehrung)
//   potCap  = feste Topf-Obergrenze -> max. Teilnehmer = potCap ÷ stake
//   starters/dropouts = simulierter Pool-Zustand -> daraus wird "increase" gerechnet.
// pot / payout / "increase in value" stehen hier NICHT — sie werden abgeleitet
// (siehe BetEconomics). Meist EUR; die adidas-Wette ist USD (zeigt: ein Pot = eine
// Waehrung, aber App-weit mehrere Waehrungen moeglich). UniversityRun19 ist absichtlich
// VOLL (starters = max) — demonstriert den geschlossenen Topf.

import '../models/bet.dart';
import '../models/money.dart';

final sampleBets = <Bet>[
  Bet(
    name: 'Dominator', sport: Sport.jogging, distanceKm: 7, iterationsPerWeek: 2, expirationDays: 10,
    stake: Money.of(10, 'EUR'), potCap: Money.of(2000, 'EUR'), starters: 80, dropouts: 12,
  ),
  Bet(
    name: 'Tribun 11', sport: Sport.jogging, distanceKm: 7.5, iterationsPerWeek: 3, expirationDays: 303,
    stake: Money.of(45, 'EUR'), potCap: Money.of(9000, 'EUR'), starters: 150, dropouts: 95,
  ),
  Bet(
    name: 'GetAll', sport: Sport.jogging, distanceKm: 7, iterationsPerWeek: 4, expirationDays: 12,
    stake: Money.of(20, 'EUR'), potCap: Money.of(2000, 'EUR'), starters: 70, dropouts: 40,
  ),
  Bet(
    name: 'adidas Summerrun', sport: Sport.jogging, distanceKm: 8, iterationsPerWeek: 1, expirationDays: 126,
    stake: Money.of(1, 'USD'), potCap: Money.of(5000, 'USD'), starters: 3200, dropouts: 3100, tag: BetTag.sponsored,
  ),
  Bet(
    name: 'UniversityRun19', sport: Sport.jogging, distanceKm: 198.5, iterationsPerWeek: 2, expirationDays: 23,
    stake: Money.of(50, 'EUR'), potCap: Money.of(5000, 'EUR'), starters: 100, dropouts: 88,
  ),
  Bet(
    name: 'RunRunRun', sport: Sport.jogging, distanceKm: 9, iterationsPerWeek: 7, expirationDays: 356,
    stake: Money.of(30, 'EUR'), potCap: Money.of(6000, 'EUR'), starters: 45, dropouts: 6,
  ),
  Bet(
    name: 'Bellymelters', sport: Sport.jogging, distanceKm: 14, iterationsPerWeek: 2, expirationDays: 165,
    stake: Money.of(80, 'EUR'), potCap: Money.of(8000, 'EUR'), starters: 55, dropouts: 20,
  ),
];
