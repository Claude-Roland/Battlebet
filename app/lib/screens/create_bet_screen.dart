// Wette anlegen (Katalog: `CreateBetScreen`).
// Wählwalzen für Distanz, Häufigkeit/Woche, Dauer (Wochen) und Einsatz; darunter
// die Wahl des POT-TYPS (Limited 500 / Limited large 2000 / Unlimited). Der Pot-Typ
// bestimmt Deckel und Zugang. Was die eigene Vertrauensstufe (noch) nicht eröffnen
// darf, ist ausgegraut + gesperrt — sichtbar als Anreiz (Roland-Prinzip).
// Geld läuft über den Money-Typ (EUR). MVP: Sportart fest = jogging.
//
// Bewusste Design-Entscheidung: klare, konsistente Optik (CupertinoPicker mit
// dezentem Auswahlband) — NICHT die metallische Original-Trommel nachgebaut.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/my_bets_store.dart';
import '../data/user_session.dart';
import '../models/bet.dart';
import '../models/money.dart';
import '../models/tiers.dart';
import '../theme/app_theme.dart';
import '../widgets/top_nav.dart';
import 'my_bets_screen.dart';

class CreateBetScreen extends StatefulWidget {
  const CreateBetScreen({super.key});

  @override
  State<CreateBetScreen> createState() => _CreateBetScreenState();
}

class _CreateBetScreenState extends State<CreateBetScreen> {
  // Alle Wetten hier laufen in EUR (Money-Typ traegt die Waehrung mit).
  static const _currency = 'EUR';

  final List<double> _distances = [for (int i = 0; i <= 54; i++) 3 + i * 0.5]; // 3.0 .. 30.0 km
  final List<int> _freqs = [for (int i = 1; i <= 7; i++) i]; // 1 .. 7 x/Woche
  final List<int> _weeks = [for (int i = 1; i <= 52; i++) i]; // 1 .. 52 Wochen
  final List<int> _prices = [for (int i = 1; i <= 100; i++) i]; // 1 .. 100 € Einsatz

  int _iDist = 9; // 7.5 km
  int _iFreq = 4; // 5 x week
  int _iWeek = 7; // 8 weeks
  int _iPrice = 19; // 20 €

  PotTier _tier = PotTier.limited; // Standard: der fuer alle offene Pot
  Sport _sport = Sport.jogging; // gewaehlte Sportart (jogging/running/hiking)

  late final _distCtrl = FixedExtentScrollController(initialItem: _iDist);
  late final _freqCtrl = FixedExtentScrollController(initialItem: _iFreq);
  late final _weekCtrl = FixedExtentScrollController(initialItem: _iWeek);
  late final _priceCtrl = FixedExtentScrollController(initialItem: _iPrice);

  @override
  void initState() {
    super.initState();
    userSession.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    userSession.removeListener(_onUserChanged);
    _distCtrl.dispose();
    _freqCtrl.dispose();
    _weekCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  /// Status umgeschaltet -> falls die gewaehlte Stufe nun gesperrt ist, herunterklemmen.
  void _onUserChanged() {
    if (!_tier.allows(userSession.tier)) _tier = userSession.tier.maxPot;
    setState(() {});
  }

  double get _distance => _distances[_iDist];
  int get _freq => _freqs[_iFreq];
  int get _week => _weeks[_iWeek];
  int get _price => _prices[_iPrice];

  int get _maxRunners => (_tier.capMajor == null || _price <= 0) ? 0 : _tier.capMajor! ~/ _price;

  String _fmtKm(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toString();

  String get _verb => switch (_sport) {
        Sport.running => 'run',
        Sport.wandern => 'hike',
        _ => 'jog',
      };

  String _asset(Sport s) => switch (s) {
        Sport.running => 'Renner-Icon.svg',
        Sport.wandern => 'Wanderer-Icon.svg',
        _ => 'Jogger-Icon.svg',
      };

  Widget _sportChip(Sport s) {
    final active = _sport == s;
    return GestureDetector(
      onTap: () => setState(() => _sport = s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.orange.withValues(alpha: 0.16) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.orange : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icons/${_asset(s)}', height: 22),
            const SizedBox(width: 6),
            Text(s.label,
                style: TextStyle(
                    color: active ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String get _sentence =>
      'I bet ${Money.of(_price, _currency).format()} that I will, for the duration of $_week weeks, $_verb $_freq times a week, each time ${_fmtKm(_distance)} km.';

  /// Info zum gewaehlten Pot-Typ (Deckel + max. Teilnehmer, oder „kein Limit").
  String get _potInfoLine => _tier.isUnlimited
      ? 'Bet Tier 3 · no participant limit'
      : 'pot up to ${_tier.capIn(_currency)!.format()}  ·  max $_maxRunners runners';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TopNav(activeIndex: 1, onTap: (i) { if (i == 0) Navigator.of(context).maybePop(); }),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final s in const [Sport.jogging, Sport.running, Sport.wandern]) ...[
                      _sportChip(s),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    _wheel('distance', _distances.map(_fmtKm).toList(), _distCtrl, (i) => setState(() => _iDist = i)),
                    _wheel('x / week', _freqs.map((e) => '$e').toList(), _freqCtrl, (i) => setState(() => _iFreq = i)),
                    _wheel('weeks', _weeks.map((e) => '$e').toList(), _weekCtrl, (i) => setState(() => _iWeek = i)),
                    _wheel('entry €', _prices.map((e) => '$e').toList(), _priceCtrl, (i) => setState(() => _iPrice = i)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Text(_sentence, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.35)),
              ),
              const SizedBox(height: 16),
              // --- Pot-Typ waehlen (statusgebunden) ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('pot type',
                      style: TextStyle(color: AppColors.orange, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: PotTier.values.map(_tierOption).toList()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_potInfoLine, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, shape: const StadiumBorder()),
                    onPressed: _confirmPlace,
                    child: const Text('place bet',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Eine Pot-Typ-Option. Erlaubt = waehlbar; gesperrt = gedimmt + Schloss + Grund.
  Widget _tierOption(PotTier t) {
    final allowed = t.allows(userSession.tier);
    final selected = t == _tier;
    return Opacity(
      opacity: allowed ? 1.0 : 0.45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowed ? () => setState(() => _tier = t) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.orange.withValues(alpha: 0.16) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppColors.orange : AppColors.divider, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(
                allowed
                    ? (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked)
                    : Icons.lock_outline,
                color: selected ? AppColors.orange : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t.label,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
              ),
              Text(t.accessNote, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // "place bet" -> Bestaetigungsdialog.
  void _confirmPlace() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('place bet', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to place a bet of ${Money.of(_price, _currency).format()}.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Pot type: ${_tier.label} (${_tier.accessNote}).',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('back', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, shape: const StadiumBorder()),
            onPressed: () {
              Navigator.of(ctx).pop();
              _place();
            },
            child: const Text('place', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Wette aus der Auswahl bauen, in My Bets ablegen und dorthin wechseln.
  // Neuer Pot: nur der Ersteller (starters = 1, dropouts = 0, Standard-Fee).
  void _place() {
    final bet = Bet(
      name: '$_verb ${_fmtKm(_distance)}km',
      sport: _sport,
      distanceKm: _distance,
      iterationsPerWeek: _freq,
      expirationDays: _week * 7,
      stake: Money.of(_price, _currency),
      tier: _tier,
    );
    myBetsStore.add(bet);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MyBetsScreen()));
    messenger.showSnackBar(const SnackBar(content: Text('Bet successfully placed')));
  }

  /// Eine beschriftete Walze (WheelPicker) mit dezentem orangem Auswahlband.
  Widget _wheel(String label, List<String> items, FixedExtentScrollController ctrl, ValueChanged<int> onChanged) {
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
              magnification: 1.15,
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
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
