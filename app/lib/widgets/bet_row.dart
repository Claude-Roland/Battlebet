// Wett-Zeile (Katalog: `BetRow`) — eine Zeile der Bets-Liste.
// Zwei Textzeilen:
//   Zeile 1: Name + Sportart (+ optionaler Tag) .......... Bookmark-Flag (rechts)
//   Zeile 2: [Sport-Icon] distance | interval | expiration | entry price | increase
//
// Das Sport-Icon links ist Rolands echtes SVG (Jogger-Icon / Renner-Icon, weiss).
// Das Socken-Icon aus dem Entwurf ist Gamification und bleibt im MVP weg.
// Die Zeilen werden im BetsListScreen durch einen GrooveDivider (Trenn-Nut) getrennt.
// Antippen oeffnet spaeter die Bet-Card (noch nicht verdrahtet).
//
// Die Spaltenbreiten (flex*) sind oeffentlich, damit der Spaltenkopf exakt
// dieselben Werte nutzt und alles fluchtet.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/bet.dart';
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

  // Breite der Sport-Ikon-Spalte links und der Bookmark-Spalte rechts.
  static const double iconColWidth = 30;
  static const double bookmarkColWidth = 18;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeile 1: Name + Sportart + Tag  ...........  Bookmark
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
                const Spacer(),
                Icon(
                  bet.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: bet.bookmarked ? AppColors.orange : AppColors.textMuted,
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
              _col('${bet.entryPrice.toStringAsFixed(2)}\$', flexPrice,
                  color: AppColors.price, bold: true, align: TextAlign.right),
              _col('${bet.increaseInValuePct}%', flexIncrease,
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
      decoration: BoxDecoration(color: color.withOpacity(0.9), borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9)),
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
