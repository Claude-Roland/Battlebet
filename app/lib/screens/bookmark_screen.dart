// Bookmark-Seite (Katalog: `BookmarkScreen`) — die gemerkten Wetten.
// Erreichbar ueber das Bookmark-Symbol oben links. Server-gestuetzt (pro Konto).

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

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
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
        _bets = all.where((b) => b.bookmarked).toList();
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
            activeIndex: -1,
            onBookmarkScreen: true,
            onTap: (i) {
              if (i == 0) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              } else if (i == 1) {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const CreateBetScreen()))
                    .then((_) {
                  if (mounted) _load();
                });
              } else if (i == 2) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyBetsScreen()));
              }
            },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _error != null
                    ? _errorView()
                    : _bets.isEmpty
                        ? _empty()
                        : ListView.separated(
                            itemCount: _bets.length,
                            separatorBuilder: (c, i) => const GrooveDivider(),
                            itemBuilder: (c, i) => InkWell(
                              onTap: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (_) => BetDetailScreen(bet: _bets[i])))
                                  .then((_) {
                                if (mounted) _load();
                              }),
                              child: BetRow(bet: _bets[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, color: AppColors.textMuted, size: 40),
            SizedBox(height: 12),
            Text('No bookmarks yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            SizedBox(height: 6),
            Text('Tap the bookmark on a bet to keep it here.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
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
