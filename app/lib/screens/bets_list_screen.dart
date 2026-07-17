// Bets-Liste (Katalog: `BetsListScreen`) — die Startseite des MVP.
// Aufbau von oben nach unten:
//   1) TopNav          -> feste Navigationsleiste
//   2) Filter-Zeile    -> aktuelle Vorauswahl (jogging / 5 / 5.5 km / 5 x week)
//   3) Spaltenkoepfe   -> distance | interval | expiration | entry price | increase
//   4) Liste der BetRow, getrennt durch GrooveDivider (Trenn-Nut)

import 'package:flutter/material.dart';

import '../data/sample_bets.dart';
import '../theme/app_theme.dart';
import '../widgets/bet_row.dart';
import '../widgets/groove_divider.dart';
import '../widgets/top_nav.dart';
import 'bet_detail_screen.dart';
import 'create_bet_screen.dart';
import 'my_bets_screen.dart';

class BetsListScreen extends StatelessWidget {
  const BetsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopNav(
            activeIndex: 0,
            onTap: (i) {
              if (i == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateBetScreen()),
                );
              } else if (i == 2) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyBetsScreen()),
                );
              }
            },
          ),
          _filterRow(),
          _columnHeader(),
          // 4) Die Liste der Wetten, mit Rinnen-Trennern dazwischen.
          Expanded(
            child: ListView.separated(
              itemCount: sampleBets.length,
              separatorBuilder: (context, i) => const GrooveDivider(),
              // Antippen einer Zeile oeffnet die Bet-Card (Detailansicht).
              itemBuilder: (context, i) => InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BetDetailScreen(bet: sampleBets[i])),
                ),
                child: BetRow(bet: sampleBets[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2) Filter-/Vorauswahl-Zeile (aktuell statisch; spaeter per Waehlwalze bedient).
  Widget _filterRow() {
    return Container(
      color: AppColors.orange,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: const Row(
        children: [
          Text('jogging', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          Spacer(),
          Text('5', style: TextStyle(color: Colors.white, fontSize: 14)),
          SizedBox(width: 18),
          Text('5.5 km', style: TextStyle(color: Colors.white, fontSize: 14)),
          SizedBox(width: 18),
          Text('5 x week', style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  // 3) Spaltenkoepfe. "distance" ist die aktive Sortierung (heller + Pfeil).
  //    Nutzt dieselben flex-Werte wie BetRow, damit alles fluchtet.
  Widget _columnHeader() {
    Widget h(String t, int flex, {TextAlign align = TextAlign.left}) => Expanded(
          flex: flex,
          child: Text(t, textAlign: align, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        );

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          const SizedBox(width: BetRow.iconColWidth),
          Expanded(
            flex: BetRow.flexDistance,
            child: const Row(
              children: [
                Text('distance',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textPrimary),
              ],
            ),
          ),
          h('interval', BetRow.flexInterval),
          h('expiration', BetRow.flexExpiration),
          h('entry price', BetRow.flexPrice, align: TextAlign.right),
          h('increase', BetRow.flexIncrease, align: TextAlign.right),
          const SizedBox(width: BetRow.bookmarkColWidth),
        ],
      ),
    );
  }
}
