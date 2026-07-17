// Bet-Card / Detailansicht (Katalog: `BetDetailScreen`).
// Oeffnet sich beim Antippen einer Zeile in der Bets-Liste und zeigt die
// WETT-OEKONOMIE einer Wette:
//   Header (orange): Sport-Icon, Name, Sportart, Globus, pot / expires in /
//                    total duration / ends at
//   Body: next bet check, activities before check, interval, distance,
//         "bet data"-Kurve, participants/starters/dropouts,
//         increase in value, total price, payout, und der grosse "bet"-Button.
// Gamification (socks/batches) ist im MVP bewusst weggelassen.
//
// HINWEIS: Solange es noch kein Backend / keine echte Wett-Oekonomie gibt,
// werden pot/participants/payout/Kurve unten aus den Listen-Feldern der Wette
// BERECHNET (Platzhalter-Logik, klar gekennzeichnet).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/bet.dart';
import '../theme/app_theme.dart';
import '../widgets/digital_countdown.dart';
import '../widgets/groove_divider.dart';
import '../widgets/value_chart.dart';

class BetDetailScreen extends StatelessWidget {
  const BetDetailScreen({super.key, required this.bet});

  final Bet bet;

  // --- Abgeleitete Anzeige-Werte (Platzhalter bis zur echten Oekonomie) ---
  int get _participants => 100 + (bet.increaseInValuePct.clamp(0, 4000) ~/ 4);
  int get _dropouts => _participants ~/ 8;
  double get _pot => bet.entryPrice * _participants;
  double get _payout => bet.entryPrice * (1 + bet.increaseInValuePct / 100);

  /// Sanft steigende, leicht gezackte Kurve; Endwert ~ Wertsteigerung.
  List<double> get _valueHistory {
    const n = 16;
    final end = 1 + bet.increaseInValuePct / 100;
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
                    _kvWhite('pot', _money(_pot), big: true),
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
          Row(
            children: [
              _miniStat('participants', '$_participants'),
              _miniStat('starters', '${_participants + _dropouts}'),
              _miniStat('dropouts', '$_dropouts'),
            ],
          ),
          const GrooveDivider(),
          _kv('increase in value', '${bet.increaseInValuePct}%', valueColor: AppColors.gain, valueBig: true),
          _kv('total price', _money(bet.entryPrice)),
          _kv('payout', _money(_payout), valueColor: AppColors.price, valueBig: true),
          const SizedBox(height: 18),
          // Call to Action: der grosse "bet"-Button (Beitreten kommt spaeter).
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, shape: const StadiumBorder()),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wette platzieren kommt als Naechstes.')),
              ),
              child: const Text('bet',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
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

  /// Geldbetrag mit Tausender-Trennung und 2 Nachkommastellen, Suffix "$".
  String _money(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${buf.toString()}.${parts[1]}\$';
  }

  String _fmtKm(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toString();
}
