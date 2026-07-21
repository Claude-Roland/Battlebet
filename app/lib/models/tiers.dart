// Die Zugangs-/Vertrauens-Leiter — als BET TIER 1 / 2 / 3.
// (Zielarchitektur 8.4 + Roland-Entscheidung 2026-07-20; Details: Memory „wett-oekonomie".)
//
// NAMENS-ENTSCHEIDUNG (Roland 2026-07-20): Die Leiter heisst nach aussen
// „Bet Tier 1/2/3" — bewusst NUMMERISCH, damit sie NICHT mit den sportlichen
// Metall-/Edelstein-Stufen (SOCKS/Batches) verwechselt wird. Die Enum-Bezeichner
// heissen aus historischen Gruenden noch bronze/silber/obsidian bzw. limited/
// limitedLarge/unlimited. Der Nutzer sieht ausschliesslich die `label`-Texte.
//
// Grundregel: Ein Nutzer darf einen Pot-Typ EROEFFNEN und ihm BEITRETEN, wenn seine
// Stufe >= der geforderten Stufe des Pots ist. Gesperrtes wird ausgegraut gezeigt.
// (UI-Sprache: Englisch als Basis — Roland-Entscheidung 2026-07-20.)

import 'money.dart';

/// Vertrauens-/Zugangsstufe eines Nutzers. Reihenfolge = Rang (1 < 2 < 3).
enum UserTier { bronze, silber, obsidian }

extension UserTierX on UserTier {
  String get label => switch (this) {
        UserTier.bronze => 'Tier 1',
        UserTier.silber => 'Tier 2',
        UserTier.obsidian => 'Unlimited',
      };
  int get rank => index;

  /// Hoechster Pot-Typ, den ein Nutzer dieser Stufe eroeffnen/betreten darf.
  PotTier get maxPot => switch (this) {
        UserTier.bronze => PotTier.limited,
        UserTier.silber => PotTier.limitedLarge,
        UserTier.obsidian => PotTier.unlimited,
      };
}

/// Typ eines Pots = Groesse + Zugang. Deckt sich mit der Bet-Tier-Leiter.
enum PotTier { limited, limitedLarge, unlimited }

extension PotTierX on PotTier {
  /// Mindest-Nutzerstufe zum Eroeffnen UND Beitreten.
  UserTier get requires => switch (this) {
        PotTier.limited => UserTier.bronze,
        PotTier.limitedLarge => UserTier.silber,
        PotTier.unlimited => UserTier.obsidian,
      };

  bool get isUnlimited => this == PotTier.unlimited;

  /// Fester Topf-Deckel in ganzen Waehrungseinheiten; null = unbegrenzt.
  int? get capMajor => switch (this) {
        PotTier.limited => 500,
        PotTier.limitedLarge => 2000,
        PotTier.unlimited => null,
      };

  /// Anzeigename: Bet-Tier-Nummer + Deckel-Gefuehl (EN-Basis).
  String get label => switch (this) {
        PotTier.limited => 'Tier 1 · up to 500',
        PotTier.limitedLarge => 'Tier 2 · up to 2000',
        PotTier.unlimited => 'Unlimited',
      };

  /// Kurzform fuer enge Stellen (Listen-Zeile).
  String get shortLabel => switch (this) {
        PotTier.limited => 'Tier 1',
        PotTier.limitedLarge => 'Tier 2',
        PotTier.unlimited => 'Unlimited',
      };

  /// Kurz-Zugangshinweis fuer die Legende (EN-Basis).
  String get accessNote => switch (this) {
        PotTier.limited => 'open to all',
        PotTier.limitedLarge => 'from Tier 2',
        PotTier.unlimited => 'Unlimited tier only',
      };

  /// Der Deckel als Money in der gewuenschten Waehrung; null bei unbegrenzt.
  Money? capIn(String currency) => isUnlimited ? null : Money.of(capMajor!, currency);

  /// Darf ein Nutzer dieser Stufe hier eroeffnen/beitreten?
  bool allows(UserTier user) => user.rank >= requires.rank;
}
