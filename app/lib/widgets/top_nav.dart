// Top-Navigation (Katalog: `TopNav`) — die feste obere Leiste.
// Reiter: bets | create bet | my bets, plus Bookmark links und Profil rechts.
// `onTap(index)` meldet Reiter-Taps (0=bets, 1=create bet, 2=my bets); der
// jeweilige Screen entscheidet, wohin navigiert wird.

import 'package:flutter/material.dart';

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
            color: Colors.white.withOpacity(active ? 1 : 0.75),
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
