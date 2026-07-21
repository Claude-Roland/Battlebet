// Onboarding: Anmeldung/Registrierung (Katalog: `AuthScreen`).
// Einstieg der App. Nutzer meldet sich an ODER registriert sich mit Username +
// Passwort. MVP: rein lokal (kein Backend) über `authStore`. Nach Erfolg geht
// es weiter in die Bets-Liste. UI-Sprache: Englisch als Basis (Roland 2026-07-20).

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_store.dart';
import '../data/session_store.dart';
import '../theme/app_theme.dart';
import 'bets_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // true = Registrieren (neues Konto), false = Anmelden (bestehendes Konto).
  bool _register = true;
  bool _obscure = true;
  bool _busy = false;
  bool _remember = true;

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _setMode(bool register) {
    if (register == _register) return;
    setState(() {
      _register = register;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final user = _userCtrl.text;
    final pass = _passCtrl.text;
    setState(() {
      _busy = true;
      _error = null;
    });
    // authStore spricht mit dem Server; Fehlermeldung oder null bei Erfolg.
    final err = _register
        ? await authStore.register(user, pass)
        : await authStore.login(user, pass);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _busy = false;
      });
      return;
    }
    if (_remember && api.token != null) {
      await sessionStore.save(api.token!);
    } else if (!_remember) {
      await sessionStore.clear();
    }
    if (!mounted) return;
    // Erfolg: rein in die App, Onboarding aus dem Stack nehmen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BetsListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Wordmark(),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ModeToggle(register: _register, onChanged: _setMode),
                    const SizedBox(height: 24),
                    _Field(
                      label: 'Username',
                      controller: _userCtrl,
                      hint: 'your username',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Password',
                      controller: _passCtrl,
                      hint: 'your password',
                      obscure: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      trailing: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFE0684F), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(color: Color(0xFFE0684F), fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _remember,
                            onChanged: (v) => setState(() => _remember = v ?? false),
                            activeColor: AppColors.orange,
                            side: const BorderSide(color: AppColors.textMuted),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _remember = !_remember),
                            child: const Text('Remember this device for 30 days',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_register ? 'Create account' : 'Log in'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _register ? 'Already have an account? Tap "Log in" above.' : 'New here? Tap "Register" above.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oranger Kopfbereich mit Wortmarke und Claim.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.orange,
      padding: const EdgeInsets.fromLTRB(28, 44, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'BATTLEBET',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Bet on yourself',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Segmentierter Umschalter „Log in | Register".
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.register, required this.onChanged});

  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _seg('Log in', !register, () => onChanged(false)),
          _seg('Register', register, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Beschriftetes, dunkles Eingabefeld mit optionalem Trailing-Icon.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.trailing,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final Widget? trailing;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  cursorColor: AppColors.orange,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}
