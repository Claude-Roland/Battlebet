// Bet-Card / Detailansicht (Katalog: `BetDetailScreen`).
// Oeffnet sich beim Antippen einer Zeile in der Bets-Liste und zeigt die
// WETT-OEKONOMIE einer Wette:
//   Header (orange): Sport-Icon, Name, Sportart, Globus, pot / expires in /
//                    total duration / ends at
//   Body: next bet check, activities before check, interval, distance,
//         "bet data"-Kurve, participants/starters/dropouts,
//         increase in value, stake, fee, payout, pot cap, und der "bet"-Knopf.
// Gamification (socks/batches) ist im MVP bewusst weggelassen.
//
// Die Pot-Zahlen (pot, payout, increase, Deckel) sind KEINE Platzhalter mehr:
// sie werden von `BetEconomics` aus den echten Vertragsfeldern der Wette
// gerechnet (Einsatz, Topf-Deckel, Fee, Starter, Aussteiger). Geld ist `Money`.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/my_bets_store.dart';
import '../models/bet.dart';
import '../models/bet_economics.dart';
import '../theme/app_theme.dart';
import '../widgets/digital_countdown.dart';
import '../widgets/groove_divider.dart';
import '../widgets/value_chart.dart';
import 'my_bets_screen.dart';

/// Gruen fuer den "bereits platziert"-Zustand (wie in my_bets_screen).
const _joinedGreen = Color(0xFF6FBF3B);

class BetDetailScreen extends StatelessWidget {
  const BetDetailScreen({super.key, required this.bet});

  final Bet bet;

  /// Die gerechnete Pot-Oekonomie dieser Wette (Single Source der Anzeige-Zahlen).
  BetEconomics get _eco => bet.economics;

  /// Kurve fuer "bet data": steigt sanft bis zur aktuellen Wertsteigerung.
  List<double> get _valueHistory {
    const n = 16;
    final end = 1 + _eco.increasePct / 100;
    return List.generate(n, (i) {
      final t = i / (n - 1);
      final zig = (i.isEven) ? 0.04 : -0.03;
      return (1 + (end - 1) * t) + zig;
    });
  }

  String get _endsAt {
    final d = DateTime.now().add(Duration(days: bet.expirationDays));
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get _sportAsset => bet.sport == Sport.running ? 'Renner-Icon.svg' : 'Jogger-Icon.svg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            Expanded(child: SingleChildScrollView(child: _body(context))),
          ],
        ),
      ),
    );
  }

  // ---- Header (orange) ----
  Widget _header(BuildContext context) {
    return Container(
      color: AppColors.orange,
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              const Icon(Icons.public, color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          Text(bet.name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700)),
          Text(bet.sport.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SvgPicture.asset('assets/icons/$_sportAsset', height: 76),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    // Aktueller Topf (Einsatz × Starter).
                    _kvWhite('pot', _eco.pot.format(), big: true),
                    _kvWhite('expires in', '${bet.expirationDays}d'),
                    _kvWhite('total duration', '${bet.expirationDays}d'),
                    _kvWhite('ends at', _endsAt),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Body (dunkel) ----
  Widget _body(BuildContext context) {
    final feePct = (bet.feeBps / 100).toStringAsFixed(bet.feeBps % 100 == 0 ? 0 : 1);
    final active = bet.starters - bet.dropouts;
    final increaseColor = _eco.increasePctRounded >= 0 ? AppColors.gain : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Countdown in Digital-Ziffern (Sieben-Segment).
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: const [
                Expanded(child: Text('next bet check', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
                DigitalCountdown('2d 06h 12m'),
              ],
            ),
          ),
          _kv('activities before the next bet check', '${bet.iterationsPerWeek}'),
          _kv('interval', '${bet.iterationsPerWeek} x week'),
          _kv('distance', '${_fmtKm(bet.distanceKm)} km'),
          const GrooveDivider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('bet data',
                style: TextStyle(color: AppColors.orange, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          ValueChart(data: _valueHistory),
          const SizedBox(height: 10),
          // participants = aktuell noch dabei; starters = alle, die eingezahlt haben;
          // dropouts = ausgestiegen (Einsatz bleibt im Topf).
          Row(
            children: [
              _miniStat('participants', '$active'),
              _miniStat('starters', '${bet.starters}'),
              _miniStat('dropouts', '${bet.dropouts}'),
            ],
          ),
          const GrooveDivider(),
          // --- Echte Pot-Oekonomie ---
          _kv('increase in value', '${_eco.increasePctRounded}%', valueColor: increaseColor, valueBig: true),
          _kv('stake', bet.stake.format()),
          _kv('platform fee ($feePct%)', '- ${_eco.fee.format()}'),
          _kv('payout', _eco.payoutPerFinisher.format(), valueColor: AppColors.price, valueBig: true),
          _kv('pot cap', '${bet.potCap.format()}  ·  max ${_eco.maxStarters}'),
          // Pruefprofil ist vor dem Beitritt sichtbar (Zielarchitektur 8.1.3);
          // heute immer "standard" — Samen fuer die spaetere Bronze/Silber/Obsidian-Leiter.
          _kv('check profile', bet.checkProfile.name),
          const SizedBox(height: 18),
          // Call to Action: der grosse "bet"-Knopf. Drei Zustaende, reagieren auf den Store:
          //   schon beigetreten -> gesperrt "placed" (fuehrt zu My Bets)
          //   Topf voll          -> gesperrt "pot full" (kein heimliches Aufsteigen)
          //   sonst              -> oranger "bet"-Knopf (oeffnet Bestaetigung)
          AnimatedBuilder(
            animation: myBetsStore,
            builder: (context, _) {
              final joined = myBetsStore.hasJoined(bet);
              final full = bet.economics.isFull;
              return SizedBox(
                height: 52,
                child: joined
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          shape: const StadiumBorder(),
                          side: const BorderSide(color: _joinedGreen, width: 1.5),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyBetsScreen()),
                        ),
                        icon: const Icon(Icons.check_circle, color: _joinedGreen, size: 20),
                        label: const Text('placed · view in My Bets',
                            style: TextStyle(color: _joinedGreen, fontSize: 15, fontWeight: FontWeight.w700)),
                      )
                    : full
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              shape: const StadiumBorder(),
                              disabledBackgroundColor: AppColors.surface,
                            ),
                            onPressed: null,
                            icon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18),
                            label: const Text('pot full · closed',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.w700)),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange, shape: const StadiumBorder()),
                            onPressed: () => _confirmJoin(context),
                            child: const Text('bet',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---- Beitreten (Bestaetigung -> ablegen -> zu My Bets) ----

  /// Bestaetigungsdialog vor dem Beitreten: zeigt Einsatz und die (festen)
  /// Bedingungen der Wette. Analog zum "place bet"-Dialog beim Wette-Anlegen.
  void _confirmJoin(BuildContext context) {
    final weeks = (bet.expirationDays / 7).round();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('place bet', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to join "${bet.name}".',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 14),
            _confirmRow('stake', bet.stake.format(), valueColor: AppColors.price),
            const SizedBox(height: 6),
            _confirmRow('goal', '${_fmtKm(bet.distanceKm)} km · ${bet.iterationsPerWeek}× a week · $weeks weeks'),
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
              _join(context);
            },
            child: const Text('place', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Wette in "My Bets" ablegen und dorthin wechseln (ersetzt die Detailseite).
  void _join(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    myBetsStore.add(bet);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MyBetsScreen()),
    );
    messenger.showSnackBar(const SnackBar(content: Text('Bet successfully placed')));
  }

  /// Eine Zeile im Bestaetigungsdialog: schmales Label links, Wert rechts.
  Widget _confirmRow(String label, String value, {Color valueColor = AppColors.textPrimary}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 52,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
        Expanded(
            child: Text(value,
                style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w700))),
      ],
    );
  }

  // ---- kleine Bausteine ----

  /// Label links, Wert rechts (heller Body-Stil).
  Widget _kv(String label, String value, {Color valueColor = AppColors.textPrimary, bool valueBig = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: valueBig ? 22 : 15,
                  fontWeight: valueBig ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }

  /// Label links, Wert rechts (weisser Header-Stil).
  Widget _kvWhite(String label, String value, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Text(value,
              style: TextStyle(color: Colors.white, fontSize: big ? 18 : 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _fmtKm(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toString();
}
