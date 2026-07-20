// Bets-Liste (Katalog: `BetsListScreen`) — die Startseite des MVP.
// Aufbau von oben nach unten:
//   1) TopNav             -> feste Navigationsleiste
//   2) Filter-Zeile       -> aktuelle Vorauswahl (jogging / 5 / 5.5 km / 5 x week)
//   3) SORTIER-KOPFZEILE  -> vier antippbare Schluessel: Neu | Distanz | Einsatz | Wertzuwachs
//      Der aktive Schluessel ist orange + traegt einen Richtungspfeil; nochmal
//      antippen dreht die Richtung (auf-/absteigend). Ein anderer Schluessel
//      startet mit seiner sinnvollen Standardrichtung.
//   4) Liste der BetRow, getrennt durch GrooveDivider (Trenn-Nut), sortiert nach
//      dem aktiven Schluessel.

import 'package:flutter/material.dart';

import '../data/sample_bets.dart';
import '../models/bet.dart';
import '../theme/app_theme.dart';
import '../widgets/bet_row.dart';
import '../widgets/groove_divider.dart';
import '../widgets/top_nav.dart';
import 'bet_detail_screen.dart';
import 'create_bet_screen.dart';
import 'my_bets_screen.dart';

/// Wonach die Liste sortiert wird (Rolands schlanke Vier).
enum BetSortKey { neu, distanz, einsatz, wertzuwachs }

extension _BetSortKeyX on BetSortKey {
  String get label => switch (this) {
        BetSortKey.neu => 'Neu',
        BetSortKey.distanz => 'Distanz',
        BetSortKey.einsatz => 'Einsatz',
        BetSortKey.wertzuwachs => 'Wertzuwachs',
      };

  /// Voreingestellte Richtung beim WECHSEL auf diesen Schluessel
  /// (nochmal antippen dreht sie dann jeweils um).
  bool get defaultDesc => switch (this) {
        BetSortKey.neu => true, // neueste zuerst
        BetSortKey.distanz => false, // kuerzeste zuerst
        BetSortKey.einsatz => false, // guenstigste zuerst
        BetSortKey.wertzuwachs => true, // groesster Zuwachs zuerst
      };
}

class BetsListScreen extends StatefulWidget {
  const BetsListScreen({super.key});

  @override
  State<BetsListScreen> createState() => _BetsListScreenState();
}

class _BetsListScreenState extends State<BetsListScreen> {
  BetSortKey _key = BetSortKey.neu; // Start: neueste zuerst
  bool _desc = true;

  void _onSort(BetSortKey key) {
    setState(() {
      if (_key == key) {
        _desc = !_desc; // gleicher Schluessel -> Richtung drehen
      } else {
        _key = key;
        _desc = key.defaultDesc; // neuer Schluessel -> sinnvolle Startrichtung
      }
    });
  }

  /// Vergleichswert je Schluessel. Geld wird ueber die Cent-Einheit (`minor`)
  /// verglichen; die Waehrungen sind im MVP gemischt (der USD-Ausreisser adidas
  /// faellt dadurch nach unten) — spaeter mit echter Umrechnung sauber.
  int _cmp(Bet a, Bet b) {
    switch (_key) {
      case BetSortKey.neu:
        return a.createdSeq.compareTo(b.createdSeq);
      case BetSortKey.distanz:
        return a.distanceKm.compareTo(b.distanceKm);
      case BetSortKey.einsatz:
        return a.stake.minor.compareTo(b.stake.minor);
      case BetSortKey.wertzuwachs:
        return a.economics.increasePct.compareTo(b.economics.increasePct);
    }
  }

  List<Bet> get _sortedBets {
    final list = [...sampleBets];
    list.sort((a, b) => _desc ? _cmp(b, a) : _cmp(a, b));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bets = _sortedBets;
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
          _sortHeader(),
          // 4) Die Liste der Wetten, mit Rinnen-Trennern dazwischen.
          Expanded(
            child: ListView.separated(
              itemCount: bets.length,
              separatorBuilder: (context, i) => const GrooveDivider(),
              // Antippen einer Zeile oeffnet die Bet-Card (Detailansicht).
              itemBuilder: (context, i) => InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BetDetailScreen(bet: bets[i])),
                ),
                child: BetRow(bet: bets[i]),
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

  // 3) Sortier-Kopfzeile: links ein Sortier-Symbol, dann die vier Schluessel
  //    gleichmaessig verteilt. Aktiver Schluessel orange + Richtungspfeil.
  Widget _sortHeader() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      child: Row(
        children: [
          const Icon(Icons.swap_vert, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sortItem(BetSortKey.neu),
                _sortItem(BetSortKey.distanz),
                _sortItem(BetSortKey.einsatz),
                _sortItem(BetSortKey.wertzuwachs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortItem(BetSortKey key) {
    final active = _key == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onSort(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              key.label,
              style: TextStyle(
                color: active ? AppColors.orange : AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (active)
              Icon(
                _desc ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                size: 18,
                color: AppColors.orange,
              ),
          ],
        ),
      ),
    );
  }
}
