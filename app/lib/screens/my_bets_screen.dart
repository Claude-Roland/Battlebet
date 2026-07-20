// Meine Wetten (Katalog: `MyBetsScreen`).
// Zeigt die platzierten Wetten mit Fortschritt. Über „record run" öffnet sich der
// RECORDER: ein aufgenommener, qualifizierter Lauf schreibt eine Aktivität gut
// — die Wette macht Fortschritt, bis sie geschafft ist.
//
// Konsistenz mit der Bets-Liste/Detailansicht (Roland-Wunsch 2026-07-20): jede
// Kachel zeigt Sport-Icon (aus der Sportart), Bet-Tier, RESTLAUFZEIT („expires in")
// und den ABGELEITETEN Wertzuwachs — dieselben Kennzahlen wie im Katalog.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/my_bets_store.dart';
import '../models/bet.dart';
import '../models/tiers.dart';
import '../theme/app_theme.dart';
import '../widgets/groove_divider.dart';
import '../widgets/top_nav.dart';
import 'create_bet_screen.dart';
import 'recorder_screen.dart';

const _green = Color(0xFF6FBF3B);

class MyBetsScreen extends StatelessWidget {
  const MyBetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopNav(
            activeIndex: 2,
            onTap: (i) {
              if (i == 0) {
                Navigator.of(context).maybePop();
              } else if (i == 1) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateBetScreen()));
              }
            },
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: myBetsStore,
              builder: (context, _) {
                final bets = myBetsStore.bets;
                if (bets.isEmpty) return const _EmptyState();
                return ListView.separated(
                  itemCount: bets.length,
                  separatorBuilder: (c, i) => const GrooveDivider(),
                  itemBuilder: (c, i) => _MyBetTile(placed: bets[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, color: AppColors.textMuted, size: 40),
            SizedBox(height: 12),
            Text('No bets placed yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            SizedBox(height: 6),
            Text('Create and place a bet via "create bet".',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MyBetTile extends StatelessWidget {
  const _MyBetTile({required this.placed});

  final PlacedBet placed;

  @override
  Widget build(BuildContext context) {
    final bet = placed.bet;
    final done = placed.isComplete;
    final pct = (placed.progress * 100).round();
    final increase = bet.economics.increasePctRounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeile 1: Sport-Icon + Name + Einsatz
          Row(
            children: [
              SvgPicture.asset('assets/icons/${_sportAsset(bet.sport)}', height: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(bet.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Text(bet.stake.format(),
                  style: const TextStyle(color: AppColors.price, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          // Zeile 2: Sportart · Distanz · Häufigkeit + Bet-Tier-Chip
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${bet.sport.label} · ${_fmtKm(bet.distanceKm)} km · ${bet.iterationsPerWeek}×/week',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                _tierChip(bet.tier),
              ],
            ),
          ),
          const SizedBox(height: 5),
          // Zeile 3: RESTLAUFZEIT + Wertzuwachs (dieselben Kennzahlen wie im Katalog)
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('expires in ${bet.expirationDays}d',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const Spacer(),
                Text('value ${increase >= 0 ? '+' : ''}$increase%',
                    style: const TextStyle(color: AppColors.gain, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.only(left: 30), child: _progressBar(placed.progress, done)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              children: [
                Expanded(
                  child: Text('${placed.activitiesDone} / ${placed.totalActivities} activities  ·  $pct%',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ),
                if (done)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: _green, size: 16),
                      SizedBox(width: 4),
                      Text('done', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  )
                else
                  _recordButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fortschritt als PILLENRINNE: heller Kanal, darin der gefuellte Anteil als Pille.
  Widget _progressBar(double p, bool done) {
    const h = 8.0;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(h / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: p.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: done ? _green : AppColors.orange,
            borderRadius: BorderRadius.circular(h / 2),
          ),
        ),
      ),
    );
  }

  /// Bet-Tier-Chip (Tier 1/2/3) — wie in der Bets-Liste.
  Widget _tierChip(PotTier tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(tier.shortLabel,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }

  /// Öffnet den Recorder für DIESE Wette. Ein qualifizierter Lauf zählt als Aktivität.
  Widget _recordButton(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecorderScreen(placed: placed))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
            SizedBox(width: 5),
            Text('record run',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  /// Sportart -> SVG-Asset (Icon-Policy: aus der Sportart abgeleitet, nie hart verdrahtet).
  String _sportAsset(Sport s) => s == Sport.running ? 'Renner-Icon.svg' : 'Jogger-Icon.svg';

  String _fmtKm(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toString();
}
