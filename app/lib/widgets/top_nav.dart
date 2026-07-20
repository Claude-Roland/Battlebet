// Top-Navigation (Katalog: `TopNav`) — die feste obere Leiste.
// Reiter: bets | create bet | my bets, plus Bookmark links und Profil rechts.
// `onTap(index)` meldet Reiter-Taps (0=bets, 1=create bet, 2=my bets); der
// jeweilige Screen entscheidet, wohin navigiert wird.
//
// Rechts sitzt ein kleiner VORSCHAU-Chip (science-Symbol) mit der aktuellen
// Vertrauensstufe (Bronze/Silber/Obsidian). Antippen schaltet die Stufe weiter —
// so sieht man live, wie sich Ausgrauen/Freigeben von Pots aendert. Nur ein
// Entwickler-/Vorschau-Hilfsmittel, faellt spaeter weg.

import 'package:flutter/material.dart';

import '../data/user_session.dart';
import '../models/tiers.dart';
import '../theme/app_theme.dart';

class TopNav extends StatelessWidget {
  const TopNav({super.key, this.activeIndex = 0, this.onTap});

  /// 0 = bets, 1 = create bet, 2 = my bets.
  final int activeIndex;

  /// Wird mit dem Index des angetippten Reiters aufgerufen.
  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.orange,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.bookmark_border, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            _tab('bets', 0),
            _tab('create bet', 1),
            _tab('my bets', 2),
            const Spacer(),
            _statusChip(),
            const SizedBox(width: 8),
            const Icon(Icons.person_outline, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = index == activeIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null ? null : () => onTap!(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: active ? 1 : 0.75),
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// Vorschau-Chip: zeigt die simulierte Vertrauensstufe, tippen schaltet weiter.
  Widget _statusChip() {
    return AnimatedBuilder(
      animation: userSession,
      builder: (context, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: userSession.cycle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.science_outlined, color: Colors.white, size: 13),
              const SizedBox(width: 4),
              Text(userSession.tier.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
