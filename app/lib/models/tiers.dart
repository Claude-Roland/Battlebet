// Die Bronze/Silber/Obsidian-Leiter — Vertrauensstufe des Nutzers UND Typ eines Pots.
// (Zielarchitektur 8.4: gestufte Pots; hier als sichtbare, statusgebundene Leiter.)
//
// Grundregel (Roland 2026-07-20): Ein Nutzer darf einen Pot-Typ EROEFFNEN und ihm
// BEITRETEN, wenn seine Vertrauensstufe >= der geforderten Stufe des Pots ist.
// Was er (noch) nicht darf, wird ausgegraut sichtbar gemacht — als Anreiz.
//
//   Pot-Typ            braucht Stufe   Deckel          Zugang
//   Limited            Bronze          fest (z.B. 500) alle
//   Limited large      Silber          fest (z.B.2000) Silber + Obsidian
//   Unlimited          Obsidian        KEINER          nur Obsidian
//
// Die eigentliche staerkere Pruefung je Stufe + das echte VERDIENEN von Silber/
// Obsidian kommen mit dem Server; heute ist der Status simuliert (siehe user_session).

import 'money.dart';

/// Vertrauensstufe eines Nutzers. Reihenfolge = Rang (bronze < silber < obsidian).
enum UserTier { bronze, silber, obsidian }

extension UserTierX on UserTier {
  String get label => switch (this) {
        UserTier.bronze => 'Bronze',
        UserTier.silber => 'Silber',
        UserTier.obsidian => 'Obsidian',
      };
  int get rank => index;

  /// Hoechster Pot-Typ, den ein Nutzer dieser Stufe eroeffnen/betreten darf.
  PotTier get maxPot => switch (this) {
        UserTier.bronze => PotTier.limited,
        UserTier.silber => PotTier.limitedLarge,
        UserTier.obsidian => PotTier.unlimited,
      };
}

/// Typ eines Pots = Groesse + Zugang. Deckt sich mit der Vertrauens-Leiter.
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

  /// Anzeigename mit Zahl (Roland: „Limited 500" gibt ein Gefuehl fuer die Topfgroesse).
  String get label => switch (this) {
        PotTier.limited => 'Limited 500',
        PotTier.limitedLarge => 'Limited large 2000',
        PotTier.unlimited => 'Unlimited',
      };

  /// Kurzform ohne Zahl (fuer enge Stellen wie die Listen-Zeile).
  String get shortLabel => switch (this) {
        PotTier.limited => 'Limited',
        PotTier.limitedLarge => 'Limited large',
        PotTier.unlimited => 'Unlimited',
      };

  /// Kurz-Zugangshinweis fuer die Legende.
  String get accessNote => switch (this) {
        PotTier.limited => 'offen für alle',
        PotTier.limitedLarge => 'ab Silber',
        PotTier.unlimited => 'nur Obsidian',
      };

  /// Der Deckel als Money in der gewuenschten Waehrung; null bei unbegrenzt.
  Money? capIn(String currency) => isUnlimited ? null : Money.of(capMajor!, currency);

  /// Darf ein Nutzer dieser Stufe hier eroeffnen/beitreten?
  bool allows(UserTier user) => user.rank >= requires.rank;
}
