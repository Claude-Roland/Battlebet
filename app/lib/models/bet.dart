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
  crossCountrySkiing,
  wandern;

  /// Anzeige-Text der Sportart (wie im Entwurf).
  String get label => switch (this) {
        Sport.jogging => 'jogging',
        Sport.running => 'running',
        Sport.skating => 'skating',
        Sport.offRoadBiking => 'off-road biking',
        Sport.crossCountrySkiing => 'cross country skiing',
        Sport.wandern => 'hiking',
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
    this.createdSeq = 0,
    this.id,
    this.status = 1,
    this.joined = false,
    this.myState,
    this.createdAt,
    this.startsAt,
    this.endsAt,
    this.entryClosesAt,
    this.realStarters,
    this.minParticipants = 3,
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

  /// Reihenfolge des Anlegens (hoeher = neuer). SAMEN fuer den spaeteren echten
  /// Zeitstempel; heute treibt er nur die „Neu"-Sortierung der Liste. Der Server
  /// ersetzt das spaeter durch die echte Erstellzeit.
  final int createdSeq;

  // --- Server-Felder (null/Default bei lokalen Wetten) ---
  final String? id;
  final int status; // 0=gathering,1=running,2=resolved,3=cancelled
  final bool joined;
  final int? myState;
  final DateTime? createdAt;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? entryClosesAt;
  final int? realStarters;
  final int minParticipants;

  /// Baut eine Bet aus der Server-JSON.
  factory Bet.fromJson(Map<String, dynamic> j) {
    final si = (j['sport'] as num?)?.toInt() ?? 0;
    final ti = (j['tier'] as num?)?.toInt() ?? 0;
    final gi = (j['tag'] as num?)?.toInt() ?? 0;
    DateTime? p(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return Bet(
      id: j['id'] as String?,
      name: (j['name'] as String?) ?? '',
      sport: (si >= 0 && si < Sport.values.length) ? Sport.values[si] : Sport.jogging,
      distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
      iterationsPerWeek: (j['iterationsPerWeek'] as num?)?.toInt() ?? 1,
      expirationDays: (j['expirationDays'] as num?)?.toInt() ?? 7,
      stake: Money((j['stakeMinor'] as num?)?.toInt() ?? 0, (j['currency'] as String?) ?? 'EUR'),
      tier: (ti >= 0 && ti < PotTier.values.length) ? PotTier.values[ti] : PotTier.limited,
      feeBps: (j['feeBps'] as num?)?.toInt() ?? 1000,
      starters: (j['starters'] as num?)?.toInt() ?? 1,
      dropouts: (j['dropouts'] as num?)?.toInt() ?? 0,
      tag: (gi >= 0 && gi < BetTag.values.length) ? BetTag.values[gi] : BetTag.none,
      status: (j['status'] as num?)?.toInt() ?? 1,
      joined: (j['joined'] as bool?) ?? false,
      bookmarked: (j['bookmarked'] as bool?) ?? false,
      myState: (j['myState'] as num?)?.toInt(),
      createdAt: p(j['createdAt']),
      startsAt: p(j['startsAt']),
      endsAt: p(j['endsAt']),
      entryClosesAt: p(j['entryClosesAt']),
      realStarters: (j['realStarters'] as num?)?.toInt(),
      minParticipants: (j['minParticipants'] as num?)?.toInt() ?? 3,
    );
  }

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
