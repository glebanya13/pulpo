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
import '../../data/repositories/settings_service.dart';
import '../../data/seed/seed_demo.dart';
import '../../widgets/pressable.dart';

class OnboardingSetupScreen extends ConsumerStatefulWidget {
  const OnboardingSetupScreen({super.key});

  @override
  ConsumerState<OnboardingSetupScreen> createState() =>
      _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState
    extends ConsumerState<OnboardingSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  String _country = 'España';
  String _currency = 'EUR';
  bool _nameError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    final locale = ref.read(settingsControllerProvider).locale;
    await ref.read(settingsControllerProvider.notifier).completeOnboarding(
          name: name,
          currency: _currency,
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
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
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
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Pressable(
                      onTap: () => context.pop(),
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
                        _Dot(active: false),
                        const SizedBox(width: 6),
                        _Dot(active: true, wide: true),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                // Illustration
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(LucideIcons.user,
                        size: 40, color: AppColors.lime),
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 32),
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
                              for (final c in uniqueAppCurrencies())
                                DropdownMenuItem(
                                  value: c.country,
                                  child: Text(
                                    '${c.flag} ${c.code}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              final list = uniqueAppCurrencies();
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
                const SizedBox(height: 32),
                Pressable(
                  onTap: _finish,
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
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Pressable(
                  onTap: () => startLocalDemo(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        tr.tryDemo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
  });
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool hasError;
  final ValueChanged<String>? onChanged;

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
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
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
