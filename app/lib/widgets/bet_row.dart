// Wett-Zeile (Katalog: `BetRow`) — eine Zeile der Bets-Liste.
// Zwei Textzeilen:
//   Zeile 1: Name + Sportart (+ Tag) + Pot-Typ-Chip .......... Bookmark/Schloss
//   Zeile 2: [Sport-Icon] distance | interval | expiration | stake | increase
//
// Die Spaltenbreiten (flex*) werden auch vom Spaltenkopf in `bets_list_screen`
// benutzt, damit Kopfzeile und Datenzeile exakt fluchten.
//
// Nach Rolands Prinzip „gesperrt sichtbar als Anreiz": Pots, die die aktuelle
// Stufe (noch) nicht darf, werden GEDIMMT und tragen statt der Bookmark ein Schloss.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/user_session.dart';
import '../models/bet.dart';
import '../models/tiers.dart';
import '../theme/app_theme.dart';

class BetRow extends StatelessWidget {
  const BetRow({super.key, required this.bet});

  final Bet bet;

  // Gemeinsame Spaltenbreiten (auch vom Spaltenkopf verwendet). Auf die
  // Kopf-Beschriftungen (distance/interval/expiration/stake/increase) abgestimmt.
  static const int flexDistance = 18;
  static const int flexInterval = 15;
  static const int flexExpiration = 19;
  static const int flexPrice = 20;
  static const int flexIncrease = 18;

  // Breite der Sport-Ikon-Spalte links und der Bookmark-/Schloss-Spalte rechts.
  static const double iconColWidth = 30;
  static const double bookmarkColWidth = 18;

  // Feste Breite der Pot/Teilnehmer-Spalte der Ueberzeile. Rechtsbuendig,
  // damit die Personen-Symbole aller Zeilen exakt untereinander stehen.
  static const double potColWidth = 84;

  // Etwas Luft zwischen distance–interval und interval–expiration
  // (identisch in Kopfzeile und Datenzeile, damit beide fluchten).
  static const double colGap = 8;

  // Breite der rechtsbuendigen Meta-Spalten der Ueberzeile (Sportart, Tier).
  // Bewusst ANDERS als das Zahlenraster darunter, damit die Ueberzeile versetzt liegt.
  static const double metaSportW = 62;
  static const double metaTierW = 72;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: userSession,
      builder: (context, _) {
        final locked = !bet.tier.allows(userSession.tier);
        return Opacity(
          opacity: locked ? 0.4 : 1.0,
          child: _content(context, locked),
        );
      },
    );
  }

  Widget _content(BuildContext context, bool locked) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeile 1: Name + Sportart + Tag + Pot-Typ  ...........  Bookmark/Schloss
          Padding(
            padding: const EdgeInsets.only(left: iconColWidth, bottom: 3),
            child: Row(
              children: [
                // Name (erste Spalte, flexibel) + optionaler Tag.
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          bet.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      if (bet.tag != BetTag.none) ...[
                        const SizedBox(width: 6),
                        _tagChip(bet.tag),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Rechtsbuendige Meta-Spalten (fluchten ueber alle Zeilen).
                SizedBox(
                  width: metaSportW,
                  child: Text(
                    bet.sport.label,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: metaTierW,
                  child: Align(alignment: Alignment.centerRight, child: _tierChip(bet.tier)),
                ),
                const SizedBox(width: 4),
                // Schloss direkt hinter dem Tier (nur bei gesperrten Pots).
                SizedBox(
                  width: 14,
                  child: locked
                      ? const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 13)
                      : const SizedBox.shrink(),
                ),
                // Flexibler Zwischenraum (frueher feste 25vw-Luecke — die lief auf
                // schmalen Screens ueber und schob Pot + Bookmark aus dem Raster).
                const Spacer(flex: 1),
                // Pot / aktive Teilnehmer (Roland 2026-07-21) — feste, rechtsbuendige
                // Spalte direkt vor dem Bookmark; schrumpft notfalls statt zu ueberlaufen.
                SizedBox(
                  width: potColWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(fit: BoxFit.scaleDown, child: _participantsPot()),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: bookmarkColWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: bet.bookmarked
                        ? const Icon(Icons.bookmark, color: AppColors.orange, size: 15)
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          // Zeile 2: Sport-Icon + Zahlen-Spalten
          Row(
            children: [
              SizedBox(
                width: iconColWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset('assets/icons/${_sportAsset(bet.sport)}', height: 26),
                ),
              ),
              _col('${_fmtKm(bet.distanceKm)}km', flexDistance, bold: true, align: TextAlign.right),
              const SizedBox(width: colGap),
              _col('${bet.iterationsPerWeek} x w', flexInterval, color: AppColors.textMuted, align: TextAlign.right),
              const SizedBox(width: colGap),
              _col('${bet.expirationDays}d', flexExpiration, align: TextAlign.right),
              // Einsatz (Money) und der ABGELEITETE "increase" aus der Pot-Oekonomie.
              _col(bet.stake.format(), flexPrice,
                  color: AppColors.price, bold: true, align: TextAlign.right),
              _col('${bet.economics.increasePctRounded}%', flexIncrease,
                  color: AppColors.gain, align: TextAlign.right),
              const SizedBox(width: bookmarkColWidth),
            ],
          ),
        ],
      ),
    );
  }

  /// Kompakte Pot/Teilnehmer-Angabe der Ueberzeile: "3,456 € / 34" + kleines
  /// Personensymbol. Teilnehmer = aktuell AKTIVE (starters - dropouts).
  Widget _participantsPot() {
    final active = (bet.starters - bet.dropouts) < 0 ? 0 : bet.starters - bet.dropouts;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${bet.economics.pot.formatWhole()} / $active',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 3),
        const Icon(Icons.person, color: AppColors.textMuted, size: 12),
      ],
    );
  }

  /// Eine links-/rechts-ausgerichtete Datenspalte fester Breite.
  Widget _col(String text, int flex,
      {Color color = AppColors.textPrimary, bool bold = false, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
      ),
    );
  }

  /// Kleiner farbiger Tag (im MVP praktisch nur "sponsored").
  Widget _tagChip(BetTag tag) {
    final (String label, Color color) = switch (tag) {
      BetTag.isNew => ('new', AppColors.orange),
      BetTag.sponsored => ('sponsored', AppColors.textMuted),
      BetTag.special => ('special', AppColors.special),
      BetTag.none => ('', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9)),
    );
  }

  /// Bet-Tier-Chip (Tier 1/2/3) — als dezenter Umriss.
  Widget _tierChip(PotTier tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(tier.shortLabel,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }

  /// Ganze Zahlen ohne Nachkomma, sonst mit (7 -> "7", 7.5 -> "7.5").
  String _fmtKm(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toString();

  /// Sportart -> SVG-Asset (Icon-Policy: aus der Sportart abgeleitet).
  String _sportAsset(Sport s) => switch (s) {
        Sport.running => 'Renner-Icon.svg',
        Sport.wandern => 'Wanderer-Icon.svg',
        _ => 'Jogger-Icon.svg',
      };
}
