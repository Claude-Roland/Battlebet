// Bets-Liste (Katalog: `BetsListScreen`) — die Startseite des MVP.
// Aufbau von oben nach unten:
//   1) TopNav             -> feste Navigationsleiste
//   2) FILTER-ZEILE       -> antippbar; oeffnet das WAEHLRAD (Sport + Distanz + Einsatz + Haeufigkeit).
//   3) SORTIER-KOPFZEILE  -> jetzt SPALTEN-GENAU ausgerichtet (fluchtet mit BetRow):
//        [Uhr = New] distance | interval | expiration | stake | increase
//      Jede Spalte ist antippbar zum Sortieren; die aktive traegt einen Richtungspfeil.
//   4) Liste der BetRow (erst GEFILTERT, dann SORTIERT), getrennt durch GrooveDivider.
//
// UI-Sprache Englisch als Basis (Roland 2026-07-20).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../models/bet.dart';
import '../theme/app_theme.dart';
import '../widgets/bet_row.dart';
import '../widgets/groove_divider.dart';
import '../widgets/top_nav.dart';
import 'bet_detail_screen.dart';
import 'create_bet_screen.dart';
import 'my_bets_screen.dart';

/// Wonach die Liste sortiert wird. „neu" = Zeit (Uhr-Symbol); die anderen sind Spalten.
enum BetSortKey { neu, distanz, interval, expiration, einsatz, wertzuwachs }

extension _BetSortKeyX on BetSortKey {
  /// Voreingestellte Richtung beim WECHSEL auf diesen Schluessel.
  bool get defaultDesc => switch (this) {
        BetSortKey.neu => true, // neueste zuerst
        BetSortKey.distanz => false, // kuerzeste zuerst
        BetSortKey.interval => false, // seltenste zuerst
        BetSortKey.expiration => false, // laeuft am ehesten aus zuerst
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
  // --- Sortierung ---
  BetSortKey _key = BetSortKey.neu;
  bool _desc = true;

  // --- Filter (Waehlrad). null / 0 / 1 bedeuten „alle". ---
  static const List<Sport> _sportChoices = [Sport.jogging, Sport.running, Sport.wandern];
  static const List<double> _distSteps = [0, 5, 7, 10, 15, 20, 50, 100, 200];
  static const List<int> _stakeSteps = [0, 5, 10, 20, 30, 50, 80, 100];
  Sport? _filterSport;
  double _minDist = 0;
  int _minStake = 0;
  int _minFreq = 1;

  List<Bet> _bets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bets = await api.listBets();
      if (!mounted) return;
      setState(() {
        _bets = bets;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Cannot reach the server.';
        _loading = false;
      });
    }
  }

  void _onSort(BetSortKey key) {
    setState(() {
      if (_key == key) {
        _desc = !_desc;
      } else {
        _key = key;
        _desc = key.defaultDesc;
      }
    });
  }

  int _cmp(Bet a, Bet b) {
    switch (_key) {
      case BetSortKey.neu:
        return (a.createdAt ?? DateTime(1970)).compareTo(b.createdAt ?? DateTime(1970));
      case BetSortKey.distanz:
        return a.distanceKm.compareTo(b.distanceKm);
      case BetSortKey.interval:
        return a.iterationsPerWeek.compareTo(b.iterationsPerWeek);
      case BetSortKey.expiration:
        return a.expirationDays.compareTo(b.expirationDays);
      case BetSortKey.einsatz:
        return a.stake.minor.compareTo(b.stake.minor);
      case BetSortKey.wertzuwachs:
        return a.economics.increasePct.compareTo(b.economics.increasePct);
    }
  }

  List<Bet> get _visibleBets {
    final list = _bets
        .where((b) =>
            (_filterSport == null || b.sport == _filterSport) &&
            b.distanceKm >= _minDist &&
            b.stake.minor >= _minStake * 100 &&
            b.iterationsPerWeek >= _minFreq &&
            b.status != 2)
        .toList();
    list.sort((a, b) => _desc ? _cmp(b, a) : _cmp(a, b));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bets = _visibleBets;
    return Scaffold(
      body: Column(
        children: [
          TopNav(
            activeIndex: 0,
            onTap: (i) {
              if (i == 1) {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const CreateBetScreen()))
                    .then((_) {
                  if (mounted) _load();
                });
              } else if (i == 2) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyBetsScreen()),
                );
              }
            },
          ),
          _filterRow(),
          _sortHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _error != null
                    ? _errorView()
                    : bets.isEmpty
                        ? _emptyFilter()
                        : ListView.separated(
                            itemCount: bets.length,
                            separatorBuilder: (context, i) => const GrooveDivider(),
                            itemBuilder: (context, i) => InkWell(
                              onTap: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (_) => BetDetailScreen(bet: bets[i])))
                                  .then((_) {
                                if (mounted) _load();
                              }),
                              child: BetRow(bet: bets[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // 2) Filter-/Vorauswahl-Zeile — antippbar, oeffnet das Waehlrad.
  Widget _filterRow() {
    final sportTxt = _filterSport?.label ?? 'all sports';
    final parts = <String>[];
    if (_minDist > 0) parts.add('from ${_fmtKm(_minDist)} km');
    if (_minStake > 0) parts.add('from $_minStake €');
    if (_minFreq > 1) parts.add('from $_minFreq×/wk');
    final rest = parts.join('  ·  ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openFilter,
      child: Container(
        color: AppColors.orange,
        padding: const EdgeInsets.fromLTRB(14, 0, 12, 10),
        child: Row(
          children: [
            Text(sportTxt,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(rest,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13)),
            ),
            const Icon(Icons.tune, color: Colors.white, size: 19),
          ],
        ),
      ),
    );
  }

  // 3) Sortier-Kopfzeile: spalten-genau (nutzt dieselben flex-Werte wie BetRow).
  //    Links das Uhr-Symbol = „New" (Zeit); dann die fuenf Datenspalten, jede sortierbar.
  Widget _sortHeader() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          SizedBox(width: BetRow.iconColWidth, child: _newSort()),
          _hSort('distance', BetSortKey.distanz, BetRow.flexDistance, right: true),
          const SizedBox(width: BetRow.colGap),
          _hSort('interval', BetSortKey.interval, BetRow.flexInterval, right: true),
          const SizedBox(width: BetRow.colGap),
          _hSort('expiration', BetSortKey.expiration, BetRow.flexExpiration, right: true),
          _hSort('stake', BetSortKey.einsatz, BetRow.flexPrice, right: true),
          _hSort('increase', BetSortKey.wertzuwachs, BetRow.flexIncrease, right: true),
          const SizedBox(width: BetRow.bookmarkColWidth),
        ],
      ),
    );
  }

  /// „New"-Sortierung als Uhr-Symbol (wie im Storyboard), in der Icon-Spalte links.
  Widget _newSort() {
    final active = _key == BetSortKey.neu;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onSort(BetSortKey.neu),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 15, color: active ? AppColors.orange : AppColors.textMuted),
          if (active)
            Icon(_desc ? Icons.arrow_drop_down : Icons.arrow_drop_up, size: 13, color: AppColors.orange),
        ],
      ),
    );
  }

  /// Eine sortierbare Spalten-Kopfzelle; aktive Spalte orange + Richtungspfeil.
  Widget _hSort(String label, BetSortKey key, int flex, {bool right = false}) {
    final active = _key == key;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onSort(key),
        child: Row(
          mainAxisAlignment: right ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                textAlign: right ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: active ? AppColors.orange : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (active)
              Icon(_desc ? Icons.arrow_drop_down : Icons.arrow_drop_up, size: 14, color: AppColors.orange),
          ],
        ),
      ),
    );
  }

  // Leerzustand, wenn kein Bet zum Filter passt.
  Widget _emptyFilter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_off_outlined, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            const Text('No bet matches this filter.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() {
                _filterSport = null;
                _minDist = 0;
                _minStake = 0;
                _minFreq = 1;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.orange),
                ),
                child: const Text('Reset filter',
                    style: TextStyle(color: AppColors.orange, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Das „geoeffnete Waehlrad": vier Trommeln (Sport, Distanz, Einsatz, Haeufigkeit).
  void _openFilter() {
    final sportItems = ['all', ..._sportChoices.map((s) => s.label)];
    final distItems = _distSteps.map((d) => d == 0 ? 'all' : 'from ${_fmtKm(d)} km').toList();
    final stakeItems = _stakeSteps.map((s) => s == 0 ? 'all' : 'from $s €').toList();
    final freqItems = List.generate(7, (i) => i == 0 ? 'all' : 'from ${i + 1}×/wk');
    int sportIdx = _filterSport == null ? 0 : _sportChoices.indexOf(_filterSport!) + 1;
    if (sportIdx < 0) sportIdx = 0;
    int distIdx = _distSteps.indexOf(_minDist);
    if (distIdx < 0) distIdx = 0;
    int stakeIdx = _stakeSteps.indexOf(_minStake);
    if (stakeIdx < 0) stakeIdx = 0;
    int freqIdx = (_minFreq - 1).clamp(0, 6);
    final sportCtrl = FixedExtentScrollController(initialItem: sportIdx);
    final distCtrl = FixedExtentScrollController(initialItem: distIdx);
    final stakeCtrl = FixedExtentScrollController(initialItem: stakeIdx);
    final freqCtrl = FixedExtentScrollController(initialItem: freqIdx);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Filter',
                      style: TextStyle(color: AppColors.orange, fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      sportIdx = 0;
                      distIdx = 0;
                      stakeIdx = 0;
                      freqIdx = 0;
                      sportCtrl.jumpToItem(0);
                      distCtrl.jumpToItem(0);
                      stakeCtrl.jumpToItem(0);
                      freqCtrl.jumpToItem(0);
                    },
                    child: const Text('reset',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 176,
                child: Row(
                  children: [
                    _filterWheel('Sport', sportItems, sportCtrl, (i) => sportIdx = i),
                    _filterWheel('Distance', distItems, distCtrl, (i) => distIdx = i),
                    _filterWheel('Stake', stakeItems, stakeCtrl, (i) => stakeIdx = i),
                    _filterWheel('Frequency', freqItems, freqCtrl, (i) => freqIdx = i),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange, shape: const StadiumBorder()),
                  onPressed: () {
                    setState(() {
                      _filterSport = sportIdx == 0 ? null : _sportChoices[sportIdx - 1];
                      _minDist = _distSteps[distIdx];
                      _minStake = _stakeSteps[stakeIdx];
                      _minFreq = freqIdx + 1;
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('apply',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      sportCtrl.dispose();
      distCtrl.dispose();
      stakeCtrl.dispose();
      freqCtrl.dispose();
    });
  }

  Widget _filterWheel(
      String label, List<String> items, FixedExtentScrollController ctrl, ValueChanged<int> onChanged) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 34,
              diameterRatio: 1.1,
              squeeze: 1.2,
              useMagnifier: true,
              magnification: 1.12,
              scrollController: ctrl,
              backgroundColor: const Color(0x00000000),
              selectionOverlay: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.orange, width: 1),
                    bottom: BorderSide(color: AppColors.orange, width: 1),
                  ),
                ),
              ),
              onSelectedItemChanged: onChanged,
              children: [
                for (final it in items)
                  Center(
                    child: Text(it,
                        maxLines: 1,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(_error ?? 'Error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.orange),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.orange, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtKm(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toString();
}
