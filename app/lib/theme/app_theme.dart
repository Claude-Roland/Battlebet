// Design-Tokens der App: Farben und Textstile an EINER Stelle.
// Werte sind aus dem BattleBet-Entwurf (SVGs) abgeleitet. Sobald wir die
// Original-Schrift (Corporate S Pro) lizenzieren, wird sie hier eingehaengt.

import 'package:flutter/material.dart';

/// Zentrale Farbpalette. Nur hier definieren, ueberall referenzieren.
class AppColors {
  static const orange = Color(0xFFEC5E2A); // Marken-Akzent (Top-Leiste, Buttons)
  static const background = Color(0xFF23272E); // dunkler Seiten-Hintergrund
  static const surface = Color(0xFF2A2F37); // Zeilen/Karten, leicht heller
  static const divider = Color(0xFF3A414B); // Trennlinien
  static const textPrimary = Color(0xFFF3F4F6); // Werte, Titel
  static const textMuted = Color(0xFF9BA3AE); // Labels, Nebeninfos
  static const price = Color(0xFF3FA9E0); // Entry Price
  static const gain = Color(0xFF5BB7EA); // increase in value %
  static const special = Color(0xFFE8B33A); // "special"-Tag
}

/// Baut das globale ThemeData der App aus den Tokens oben.
ThemeData buildBattleBetTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.orange,
      surface: AppColors.surface,
    ),
    dividerColor: AppColors.divider,
  );
}
