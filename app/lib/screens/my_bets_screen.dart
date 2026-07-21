// Meine Wetten (Katalog: `MyBetsScreen`) — jetzt server-gestuetzt.
// Zeigt die Wetten, denen der Nutzer beigetreten ist (joined vom Server).
// Ueber „record run" oeffnet sich der Recorder; der aufgenommene Lauf geht an
// den Server, der ihn allen passenden aktiven Wetten zuordnet.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/api_client.dart';
import '../models/bet.dart';
import '../models/tiers.dart';
import '../theme/app_theme.dart';
import '../widgets/groove_divider.dart';
import '../widgets/top_nav.dart';
import 'create_bet_screen.dart';
import 'recorder_screen.dart';

const _green = Color(0xFF6FBF3B);

class MyBetsScreen extends StatefulWidget {
  const MyBetsScreen({super.key});

  @override
  State<MyBetsScreen> createState() => _MyBetsScreenState();
}

class _MyBetsScreenState extends State<MyBetsScreen> {
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
      final all = await api.listBets();
      if (!mounted) return;
      setState(() {
        _bets = all.where((b) => b.joined).toList();
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
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const CreateBetScreen()))
                    .then((_) {
                  if (mounted) _load();
                });
              }
            },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _error != null
                    ? _errorView()
                    : _bets.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            itemCount: _bets.length,
                            separatorBuilder: (c, i) => const GrooveDivider(),
                            itemBuilder: (c, i) => _MyBetTile(bet: _bets[i], onChanged: _load),
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
            Text('No bets joined yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            SizedBox(height: 6),
            Text('Join a bet from the list, then record your runs here.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MyBetTile extends StatelessWidget {
  const _MyBetTile({required this.bet, required this.onChanged});

  final Bet bet;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final increase = bet.economics.increasePctRounded;
    final running = bet.status == 1;
    final resolved = bet.status == 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              children: [
                Icon(_phaseIcon(bet.status), size: 13, color: _phaseColor(bet.status)),
                const SizedBox(width: 4),
                Text(_phaseText(bet),
                    style: TextStyle(color: _phaseColor(bet.status), fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('value ${increase >= 0 ? '+' : ''}$increase%',
                    style: const TextStyle(color: AppColors.gain, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              children: [
                const Spacer(),
                if (running)
                  _recordButton(context)
                else if (resolved)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: _green, size: 16),
                      SizedBox(width: 4),
                      Text('resolved', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => RecorderScreen(bet: bet)))
          .then((_) => onChanged()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(16)),
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

  String _phaseText(Bet b) => switch (b.status) {
        0 => 'gathering · needs ${b.minParticipants} to start',
        1 => 'running · expires in ${b.expirationDays}d',
        2 => 'resolved',
        _ => 'cancelled',
      };

  IconData _phaseIcon(int status) =>
      status == 0 ? Icons.hourglass_empty : Icons.schedule;

  Color _phaseColor(int status) => status == 2 ? _green : AppColors.textMuted;

  String _sportAsset(Sport s) => switch (s) {
        Sport.running => 'Renner-Icon.svg',
        Sport.wandern => 'Wanderer-Icon.svg',
        _ => 'Jogger-Icon.svg',
      };

  String _fmtKm(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toString();
}
