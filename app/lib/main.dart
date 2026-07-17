// BattleBet — App-Einstiegspunkt.
//
// Die App startet mit dem Onboarding (Katalog: `AuthScreen`): Anmelden oder
// Registrieren. Nach Erfolg geht es weiter in die Bets-Liste
// (Katalog: `BetsListScreen`). Alles Weitere folgt in kleinen Schritten.
//
// Projektaufbau (siehe Element_Katalog_MVP.md):
//   theme/   -> Farben & Textstile (Design-Tokens)
//   models/  -> Datenklassen (hier: Bet)
//   data/    -> Beispieldaten & lokale Stores (lokal, noch kein Backend)
//   widgets/ -> wiederverwendbare Bausteine (TopNav, BetRow)
//   screens/ -> ganze Seiten (AuthScreen, BetsListScreen)

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const BattleBetApp());
}

/// Wurzel-Widget der App. Setzt das dunkle BattleBet-Theme und
/// startet mit dem Onboarding (Anmelden/Registrieren) als Startseite.
class BattleBetApp extends StatelessWidget {
  const BattleBetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BattleBet',
      debugShowCheckedModeBanner: false,
      theme: buildBattleBetTheme(),
      home: const AuthScreen(),
    );
  }
}
