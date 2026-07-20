// Wette anlegen (Katalog: `CreateBetScreen`).
// Wählwalzen (WheelPicker) für Distanz, Häufigkeit/Woche, Dauer (Wochen),
// Einsatz und Topf-Deckel; aus der Auswahl wird live der Wett-Satz erzeugt.
// Der Ersteller legt die Topf-Höhe fest; daraus ergibt sich automatisch die
// maximale Teilnehmerzahl (Topf ÷ Einsatz). Geld läuft über den Money-Typ (EUR).
// MVP: Sportart fest = jogging.
//
// Bewusste Design-Entscheidung: klare, konsistente Optik (CupertinoPicker mit
// dezentem Auswahlband) — NICHT die metallische Original-Trommel nachgebaut.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/my_bets_store.dart';
import '../models/bet.dart';
import '../models/money.dart';
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
  final List<int> _potCaps = [100, 250, 500, 1000, 2500, 5000]; // Topf-Deckel in €

  int _iDist = 9; // 7.5 km
  int _iFreq = 4; // 5 x week
  int _iWeek = 7; // 8 weeks
  int _iPrice = 19; // 20 €
  int _iPotCap = 3; // 1000 €

  late final _distCtrl = FixedExtentScrollController(initialItem: _iDist);
  late final _freqCtrl = FixedExtentScrollController(initialItem: _iFreq);
  late final _weekCtrl = FixedExtentScrollController(initialItem: _iWeek);
  late final _priceCtrl = FixedExtentScrollController(initialItem: _iPrice);
  late final _potCapCtrl = FixedExtentScrollController(initialItem: _iPotCap);

  @override
  void dispose() {
    _distCtrl.dispose();
    _freqCtrl.dispose();
    _weekCtrl.dispose();
    _priceCtrl.dispose();
    _potCapCtrl.dispose();
    super.dispose();
  }

  double get _distance => _distances[_iDist];
  int get _freq => _freqs[_iFreq];
  int get _week => _weeks[_iWeek];
  int get _price => _prices[_iPrice];
  int get _potCap => _potCaps[_iPotCap];

  /// Maximale Teilnehmerzahl = Topf-Deckel ÷ Einsatz (Roland-Regel).
  int get _maxRunners => _price <= 0 ? 0 : _potCap ~/ _price;

  String _fmtKm(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toString();

  String get _sentence =>
      'I bet ${Money.of(_price, _currency).format()} that I will, for the duration of $_week weeks, jog $_freq times a week, each time ${_fmtKm(_distance)} km.';

  String get _potLine =>
      'pot up to ${Money.of(_potCap, _currency).format()}  ·  max $_maxRunners runners';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopNav(activeIndex: 1, onTap: (i) { if (i == 0) Navigator.of(context).maybePop(); }),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SvgPicture.asset('assets/icons/Jogger-Icon.svg', height: 30),
                  const SizedBox(width: 8),
                  const Text('jogging',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                  _wheel('pot cap', _potCaps.map((e) => '$e').toList(), _potCapCtrl, (i) => setState(() => _iPotCap = i)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sentence, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.35)),
                  const SizedBox(height: 8),
                  Text(_potLine, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
          ],
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
        content: Text(
            'You are about to place a bet of ${Money.of(_price, _currency).format()}.\n'
            'Pot up to ${Money.of(_potCap, _currency).format()} · max $_maxRunners runners.',
            style: const TextStyle(color: AppColors.textMuted)),
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
  void _place() {
    // Neuer Pot: nur der Ersteller (starters = 1, dropouts = 0, Standard-Fee/Profil).
    final bet = Bet(
      name: 'jog ${_fmtKm(_distance)}km',
      sport: Sport.jogging,
      distanceKm: _distance,
      iterationsPerWeek: _freq,
      expirationDays: _week * 7,
      stake: Money.of(_price, _currency),
      potCap: Money.of(_potCap, _currency),
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
