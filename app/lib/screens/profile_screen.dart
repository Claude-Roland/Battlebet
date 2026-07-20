// Profil-Seite (Katalog: `ProfileScreen`) — die Gambler-/Konto-Seite.
// Aufbau (Design-Vorlage Durchlauf 4, aber „Claudes Weg" — eigene, klare Optik):
//   1) Profil-Kopf: Avatar + Anzeigename (editierbar) + Bet-Tier.
//   2) GUTHABEN (wichtigster Teil): Betrag gross + einzahlen/auszahlen. HEUTE
//      SIMULIERT — echtes Geld kommt mit dem Server.
//   3) Erfolge: aus den platzierten Wetten abgeleitet (platziert/laufend/geschafft).
//   4) Auszeichnungen (Socken/Abzeichen/Raenge): Samen, ausgegraut als Anreiz (kommt spaeter).
//   5) Abmelden.
// Erreichbar ueber das Personen-Symbol rechts in der TopNav.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/my_bets_store.dart';
import '../data/profile_store.dart';
import '../data/user_session.dart';
import '../models/tiers.dart';
import '../theme/app_theme.dart';
import '../widgets/top_nav.dart';
import 'auth_screen.dart';
import 'create_bet_screen.dart';
import 'my_bets_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopNav(
            activeIndex: -1,
            onProfileScreen: true,
            onTap: (i) {
              if (i == 0) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              } else if (i == 1) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateBetScreen()));
              } else if (i == 2) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyBetsScreen()));
              }
            },
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([profileStore, myBetsStore, userSession, authStore]),
              builder: (context, _) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    const SizedBox(height: 14),
                    _wallet(context),
                    const SizedBox(height: 14),
                    _achievements(),
                    const SizedBox(height: 14),
                    _awardsSeed(),
                    const SizedBox(height: 22),
                    _logout(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1) Profil-Kopf: Avatar + Name (editierbar) + Bet-Tier.
  Widget _header(BuildContext context) {
    final login = authStore.currentUser ?? 'Gast';
    final name = profileStore.displayName(login);
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return _card(
      Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.orange,
            child: Text(initial,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _editName(context, name),
                      child: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 17),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_outlined, color: AppColors.orange, size: 14),
                      const SizedBox(width: 5),
                      Text(userSession.tier.label,
                          style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2) Guthaben — der wichtigste Teil: Betrag + einzahlen/auszahlen.
  Widget _wallet(BuildContext context) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Guthaben',
              style: TextStyle(color: AppColors.orange, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(profileStore.balance.format(),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text('simuliert · echtes Geld kommt mit dem Server',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _walletButton('einzahlen', Icons.add, true, () => _amountSheet(context, deposit: true))),
              const SizedBox(width: 12),
              Expanded(child: _walletButton('auszahlen', Icons.remove, false, () => _amountSheet(context, deposit: false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletButton(String label, IconData icon, bool filled, VoidCallback onTap) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? AppColors.orange : AppColors.surface,
          shape: const StadiumBorder(),
          side: filled ? null : const BorderSide(color: AppColors.orange, width: 1.4),
          elevation: 0,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: filled ? Colors.white : AppColors.orange),
        label: Text(label,
            style: TextStyle(color: filled ? Colors.white : AppColors.orange, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // 3) Erfolge: aus den platzierten Wetten abgeleitet.
  Widget _achievements() {
    final bets = myBetsStore.bets;
    final done = bets.where((b) => b.isComplete).length;
    final running = bets.length - done;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Erfolge',
              style: TextStyle(color: AppColors.orange, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (bets.isEmpty)
            const Text('Noch keine Wetten — leg los, deine Erfolge sammeln sich hier.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13))
          else
            Row(
              children: [
                Expanded(child: _stat('${bets.length}', 'platziert')),
                Expanded(child: _stat('$running', 'laufend')),
                Expanded(child: _stat('$done', 'geschafft')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  // 4) Samen: Socken / Abzeichen / Raenge — kommen spaeter, ausgegraut als Anreiz.
  Widget _awardsSeed() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Auszeichnungen',
              style: TextStyle(color: AppColors.orange, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _seed(Icons.emoji_events_outlined, 'Socken')),
              Expanded(child: _seed(Icons.workspace_premium_outlined, 'Abzeichen')),
              Expanded(child: _seed(Icons.military_tech_outlined, 'Ränge')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seed(IconData icon, String label) {
    return Opacity(
      opacity: 0.45,
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 26),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('bald', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _logout(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.divider),
          shape: const StadiumBorder(),
        ),
        onPressed: () {
          authStore.logout();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
            (r) => false,
          );
        },
        icon: const Icon(Icons.logout, size: 18, color: AppColors.textMuted),
        label: const Text('abmelden',
            style: TextStyle(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // --- Helfer ---
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }

  void _editName(BuildContext context, String currentShown) {
    final ctrl = TextEditingController(text: profileStore.customName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Anzeigename', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: currentShown,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.orange)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('abbrechen', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, shape: const StadiumBorder()),
            onPressed: () {
              profileStore.setName(ctrl.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _amountSheet(BuildContext context, {required bool deposit}) {
    const amounts = [10, 20, 50, 100, 200];
    int idx = 1; // Default 20
    final ctrl = FixedExtentScrollController(initialItem: idx);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(deposit ? 'einzahlen' : 'auszahlen',
                  style: const TextStyle(color: AppColors.orange, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SizedBox(
                height: 150,
                child: CupertinoPicker(
                  itemExtent: 36,
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
                  onSelectedItemChanged: (i) => idx = i,
                  children: [
                    for (final a in amounts)
                      Center(
                        child: Text('$a €',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, shape: const StadiumBorder()),
                  onPressed: () {
                    final a = amounts[idx];
                    if (deposit) {
                      profileStore.deposit(a);
                    } else {
                      profileStore.withdraw(a);
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('bestätigen',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(ctrl.dispose);
  }
}
