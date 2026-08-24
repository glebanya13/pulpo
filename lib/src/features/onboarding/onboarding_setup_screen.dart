import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/currencies.dart';
import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../data/seed/seed_demo.dart';
import '../../widgets/pressable.dart';
import '../auth/auth_messages.dart';
import '../auth/cloud_auth.dart';

class OnboardingSetupScreen extends ConsumerStatefulWidget {
  const OnboardingSetupScreen({super.key});

  @override
  ConsumerState<OnboardingSetupScreen> createState() =>
      _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends ConsumerState<OnboardingSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _country = 'España';
  String _currency = 'EUR';
  bool _nameError = false;
  bool _busy = false;
  bool _emailExpanded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _runAuth(Future<void> Function() fn) async {
    if (_busy) return;
    final tr = Tr.of(context);
    setState(() => _busy = true);
    try {
      await fn();
      await _completeAfterAuth();
    } catch (e) {
      if (isAuthCanceled(e)) return;
      if (!mounted) return;
      _snack(authErrorMessage(tr, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeAfterAuth() async {
    final tr = Tr.fromLang(ref.read(settingsControllerProvider).locale);
    final settings = ref.read(settingsControllerProvider);
    final typedName = _nameCtrl.text.trim();
    final name = typedName.isNotEmpty
        ? typedName
        : (settings.userName.trim().isNotEmpty &&
                settings.userName.trim().toLowerCase() != 'user'
            ? settings.userName.trim()
            : tr.guestName);

    if (typedName.isNotEmpty) {
      await ref.read(cloudAuthProvider).updateDisplayName(typedName);
      await ref.read(settingsControllerProvider.notifier).setUserName(typedName);
    }

    await ref.read(settingsControllerProvider.notifier).completeOnboarding(
          name: name,
          currency: _currency,
          currencyCountry: _country,
          themeMode: settings.themeMode,
          locale: settings.locale,
        );

    final db = ref.read(databaseProvider);
    final accounts = await db.select(db.accounts).get();
    if (accounts.isEmpty) {
      await ref.read(accountRepositoryProvider).add(
            name: tr.accountTypeCash,
            type: AccountType.cash,
            currency: _currency,
            initialBalance: double.tryParse(_balanceCtrl.text) ?? 0,
            icon: 'wallet',
            color: 0xFF3DDC84,
          );
    }
    if (mounted) context.go('/');
  }

  Future<void> _finishLocal() async {
    if (_busy) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    setState(() => _busy = true);
    try {
      final locale = ref.read(settingsControllerProvider).locale;
      await ref.read(settingsControllerProvider.notifier).completeOnboarding(
            name: name,
            currency: _currency,
            currencyCountry: _country,
            themeMode: ref.read(settingsControllerProvider).themeMode,
            locale: locale,
          );
      await ref.read(accountRepositoryProvider).add(
            name: Tr.fromLang(locale).accountTypeCash,
            type: AccountType.cash,
            currency: _currency,
            initialBalance: double.tryParse(_balanceCtrl.text) ?? 0,
            icon: 'wallet',
            color: 0xFF3DDC84,
          );
      if (mounted) context.go('/add?type=expense');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailSignIn({required bool register}) async {
    final tr = Tr.of(context);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack(tr.pleaseEnterEmailPassword);
      return;
    }
    final auth = ref.read(cloudAuthProvider);
    await _runAuth(() async {
      if (register) {
        await auth.registerWithEmail(email, password);
      } else {
        await auth.signInWithEmail(email, password);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final auth = ref.read(cloudAuthProvider);
    final showApple = !kIsWeb && Platform.isIOS;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.ink,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Pressable(
                      onTap: _busy ? null : () => context.pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.arrowLeft,
                            size: 18, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const _Dot(active: false),
                        const SizedBox(width: 6),
                        const _Dot(active: true, wide: true),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(LucideIcons.user,
                        size: 32, color: AppColors.lime),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr.setupTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr.setupSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 24),

                if (showApple) ...[
                  _AuthBtn(
                    icon: Icons.apple,
                    label: tr.signInApple,
                    enabled: !_busy,
                    onTap: () => _runAuth(auth.signInWithApple),
                  ),
                  const SizedBox(height: 10),
                ],
                _AuthBtn(
                  icon: Icons.g_mobiledata,
                  label: tr.signInGoogle,
                  enabled: !_busy,
                  onTap: () => _runAuth(auth.signInWithGoogle),
                ),

                const SizedBox(height: 10),
                Pressable(
                  onTap: _busy
                      ? null
                      : () => setState(() => _emailExpanded = !_emailExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr.signInEmail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _emailExpanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 16,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      _DarkField(
                        label: tr.email,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 8),
                      _DarkField(
                        label: tr.password,
                        controller: _passwordCtrl,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineBtn(
                              label: tr.signIn,
                              enabled: !_busy,
                              onTap: () => _emailSignIn(register: false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _OutlineBtn(
                              label: tr.register,
                              enabled: !_busy,
                              onTap: () => _emailSignIn(register: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  crossFadeState: _emailExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),

                const SizedBox(height: 18),
                _OrDivider(label: tr.orDivider),
                const SizedBox(height: 14),

                _DarkField(
                  label: tr.yourName,
                  hint: tr.howToCall,
                  controller: _nameCtrl,
                  hasError: _nameError,
                  onChanged: (_) {
                    if (_nameError) setState(() => _nameError = false);
                  },
                ),
                if (_nameError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Text(
                      tr.pleaseEnterName,
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _DarkField(
                        label: tr.initialBalance,
                        hint: '0',
                        controller: _balanceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _country,
                            isExpanded: true,
                            dropdownColor: AppColors.ink2,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            items: [
                              for (final c in appCurrencies)
                                DropdownMenuItem(
                                  value: c.country,
                                  child: Text(
                                    '${c.flag} ${c.code}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _busy
                                ? null
                                : (v) {
                                    final list = appCurrencies;
                                    final picked = list.firstWhere(
                                      (c) => c.country == v,
                                      orElse: () => list.first,
                                    );
                                    setState(() {
                                      _country = picked.country;
                                      _currency = picked.code;
                                    });
                                  },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Pressable(
                  onTap: _busy ? null : _finishLocal,
                  child: Opacity(
                    opacity: _busy ? 0.6 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          tr.finishSetup,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Pressable(
                  onTap: _busy
                      ? null
                      : () => startWithoutAccount(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        tr.continueWithoutAccount,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Pressable(
                  onTap:
                      _busy ? null : () => startLocalDemo(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(
                      child: Text(
                        tr.tryDemo,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.lime),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _AuthBtn extends StatelessWidget {
  const _AuthBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, this.wide = false});
  final bool active;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide && active ? 22 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.lime : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.hint,
    this.hasError = false,
    this.onChanged,
    this.obscureText = false,
    this.autocorrect = true,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: hasError
            ? Border.all(color: const Color(0xFFFF6B6B), width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        obscureText: obscureText,
        autocorrect: autocorrect,
        enableSuggestions: !obscureText && autocorrect,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}
