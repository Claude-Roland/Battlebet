// Lokale Beispieldaten fuer den ersten Durchstich (noch kein Backend).
// MVP-Fokus: NUR Joggen. Andere Sportarten kommen spaeter (Modell kann sie schon).
// Werte aus dem Original-Entwurf (Screen "Hauptseite Bets").

import '../models/bet.dart';

const sampleBets = <Bet>[
  Bet(name: 'Dominator', sport: Sport.jogging, distanceKm: 7, iterationsPerWeek: 2, expirationDays: 10, entryPrice: 12.50, increaseInValuePct: 5),
  Bet(name: 'Tribun 11', sport: Sport.jogging, distanceKm: 7.5, iterationsPerWeek: 3, expirationDays: 303, entryPrice: 46.65, increaseInValuePct: 234),
  Bet(name: 'GetAll', sport: Sport.jogging, distanceKm: 7, iterationsPerWeek: 4, expirationDays: 12, entryPrice: 23.67, increaseInValuePct: 89),
  Bet(name: 'adidas Summerrun', sport: Sport.jogging, distanceKm: 8, iterationsPerWeek: 1, expirationDays: 126, entryPrice: 1.00, increaseInValuePct: 4031, tag: BetTag.sponsored),
  Bet(name: 'UniversityRun19', sport: Sport.jogging, distanceKm: 198.5, iterationsPerWeek: 2, expirationDays: 23, entryPrice: 68.65, increaseInValuePct: 1154),
  Bet(name: 'RunRunRun', sport: Sport.jogging, distanceKm: 9, iterationsPerWeek: 7, expirationDays: 356, entryPrice: 67.34, increaseInValuePct: 35),
  Bet(name: 'Bellymelters', sport: Sport.jogging, distanceKm: 14, iterationsPerWeek: 2, expirationDays: 165, entryPrice: 96.36, increaseInValuePct: 34),
];
