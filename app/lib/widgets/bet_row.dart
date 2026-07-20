// Wett-Zeile (Katalog: `BetRow`) — eine Zeile der Bets-Liste.
// Zwei Textzeilen:
//   Zeile 1: Name + Sportart (+ Tag) + Pot-Typ-Chip .......... Bookmark/Schloss
//   Zeile 2: [Sport-Icon] distance | interval | expiration | entry price | increase
//
// Nach Rolands Prinzip „gesperrt sichtbar als Anreiz": Pots, die die aktuelle
// Vertrauensstufe (noch) nicht eroeffnen/betreten darf, werden GEDIMMT und tragen
// statt der Bookmark ein Schloss. Sichtbar bleiben sie — man kann sie antippen und
// ansehen, nur nicht beitreten. Reagiert live auf den Status-Umschalter.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/user_session.dart';
import '../models/bet.dart';
import '../models/tiers.dart';
import '../theme/app_theme.dart';

class BetRow extends StatelessWidget {
  const BetRow({super.key, required this.bet});

  final Bet bet;

  // Gemeinsame Spaltenbreiten (auch vom Spaltenkopf verwendet).
  static const int flexDistance = 20;
  static const int flexInterval = 16;
  static const int flexExpiration = 16;
  static const int flexPrice = 22;
  static const int flexIncrease = 14;

  // Breite der Sport-Ikon-Spalte links und der Bookmark-/Schloss-Spalte rechts.
  static const double iconColWidth = 30;
  static const double bookmarkColWidth = 18;

  @override
  Widget build(BuildContext context) {
    // Reagiert auf den Vorschau-Status: gesperrte Pots werden gedimmt.
    return AnimatedBuilder(
      animation: userSession,
      builder: (context, _) {
        final locked = !bet.tier.allows(userSession.tier);
        return Opacity(
          opacity: locked ? 0.4 : 1.0,
          child: _content(locked),
        );
      },
    );
  }

  Widget _content(bool locked) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeile 1: Name + Sportart + Tag + Pot-Typ  ...........  Bookmark/Schloss
          Padding(
            padding: const EdgeInsets.only(left: iconColWidth, bottom: 3),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${bet.name}    ${bet.sport.label}',
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
                const SizedBox(width: 6),
                _tierChip(bet.tier),
                const Spacer(),
                Icon(
                  locked ? Icons.lock_outline : (bet.bookmarked ? Icons.bookmark : Icons.bookmark_border),
                  color: locked
                      ? AppColors.textMuted
                      : (bet.bookmarked ? AppColors.orange : AppColors.textMuted),
                  size: 15,
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
              _col('${_fmtKm(bet.distanceKm)}km', flexDistance, bold: true),
              _col('${bet.iterationsPerWeek} x w', flexInterval, color: AppColors.textMuted),
              _col('${bet.expirationDays}d', flexExpiration),
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

  /// Eine links-/rechts-ausgerichtete Datenspalte fester Breite.
  Widget _col(String text, int flex,
      {Color color = AppColors.textPrimary, bool bold = false, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(color: color, fontSize: 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
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

  /// Pot-Typ-Chip (Limited / Limited large / Unlimited) — als dezenter Umriss.
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

  /// Sportart -> SVG-Asset. Aktuell nur Joggen/Rennen vorhanden;
  /// alles andere faellt vorerst auf das Jogger-Icon zurueck.
  String _sportAsset(Sport s) => switch (s) {
        Sport.running => 'Renner-Icon.svg',
        _ => 'Jogger-Icon.svg',
      };
}
