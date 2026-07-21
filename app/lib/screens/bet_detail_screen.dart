// Bet-Card / Detailansicht (Katalog: `BetDetailScreen`).
// Zeigt die WETT-OEKONOMIE einer Wette (echt gerechnet, keine Platzhalter):
//   Header (orange): Sport-Icon, Name, Sportart, Globus, pot / expires / duration / ends
//   Body: next bet check, activities, interval, distance, "bet data"-Kurve,
//         participants/starters/dropouts, increase, stake, fee, payout, pot type,
//         und der grosse "bet"-Knopf.
//
// Der "bet"-Knopf hat vier Zustaende (reagiert auf Store + Vertrauensstufe):
//   schon beigetreten     -> gesperrt "placed" (fuehrt zu My Bets)
//   Stufe zu niedrig       -> gesperrt "requires <Stufe> status"  (Anreiz)
//   Topf voll (nur limit.) -> gesperrt "pot full · closed"
//   sonst                  -> oranger "bet"-Knopf (oeffnet Bestaetigung)

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/api_client.dart';
import '../data/user_session.dart';
import '../models/bet.dart';
import '../models/bet_economics.dart';
import '../models/tiers.dart';
import '../theme/app_theme.dart';
import '../widgets/digital_countdown.dart';
import '../widgets/groove_divider.dart';
import '../widgets/value_chart.dart';

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

  String get _sportAsset => switch (bet.sport) {
        Sport.running => 'Renner-Icon.svg',
        Sport.wandern => 'Wanderer-Icon.svg',
        _ => 'Jogger-Icon.svg',
      };

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
                    _kvWhite('pot', _eco.pot.format(), big: true),
                    _kvWhite('expires in', '${bet.expirationDays}d'),
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
    final potType = bet.tier.isUnlimited
        ? '${bet.tier.label}  ·  no limit'
        : '${bet.tier.label}  ·  max ${_eco.maxStarters}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Row(
            children: [
              _miniStat('participants', '$active'),
              _miniStat('starters', '${bet.starters}'),
              _miniStat('dropouts', '${bet.dropouts}'),
            ],
          ),
          const GrooveDivider(),
          _kv('increase in value', '${_eco.increasePctRounded}%', valueColor: increaseColor, valueBig: true),
          _kv('stake', bet.stake.format()),
          _kv('platform fee ($feePct%)', '- ${_eco.fee.format()}'),
          _kv('payout', _eco.payoutPerFinisher.format(), valueColor: AppColors.price, valueBig: true),
          // Pot-Typ = Deckel + Zugang (statt der frueheren "check profile"-Zeile).
          _kv('pot type', potType),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: userSession,
            builder: (context, _) {
              final joined = bet.joined;
              final eligible = bet.tier.allows(userSession.tier);
              final full = bet.economics.isFull;
              return SizedBox(
                height: 52,
                child: joined
                    ? _placedButton(context)
                    : !eligible
                        ? _lockedButton('requires ${bet.tier.requires.label} status')
                        : full
                            ? _lockedButton('pot full · closed')
                            : _betButton(context),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---- Knopf-Zustaende ----

  Widget _betButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, shape: const StadiumBorder()),
      onPressed: () => _confirmJoin(context),
      child: const Text('bet',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _placedButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        shape: const StadiumBorder(),
        side: const BorderSide(color: _joinedGreen, width: 1.5),
      ),
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.check_circle, color: _joinedGreen, size: 20),
      label: const Text('placed',
          style: TextStyle(color: _joinedGreen, fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }

  /// Gesperrter Knopf (Status zu niedrig oder Topf voll) — sichtbar als Anreiz.
  Widget _lockedButton(String text) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.surface,
        shape: const StadiumBorder(),
      ),
      onPressed: null,
      icon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18),
      label: Text(text,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }

  // ---- Beitreten (Bestaetigung -> ablegen -> zu My Bets) ----

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
            const SizedBox(height: 6),
            _confirmRow('pot', bet.tier.label),
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

  Future<void> _join(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (bet.id == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('This bet is not on the server.')));
      return;
    }
    try {
      await api.joinBet(bet.id!);
      messenger.showSnackBar(const SnackBar(content: Text('Bet placed')));
      navigator.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not reach the server.')));
    }
  }

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
