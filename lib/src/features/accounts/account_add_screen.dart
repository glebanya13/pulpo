import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/currencies.dart';
import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';

class AccountAddScreen extends ConsumerStatefulWidget {
  const AccountAddScreen({super.key});

  @override
  ConsumerState<AccountAddScreen> createState() => _AccountAddScreenState();
}

class _AccountAddScreenState extends ConsumerState<AccountAddScreen> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  AccountType _type = AccountType.cash;
  late String _currency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currency = ref.read(settingsControllerProvider).baseCurrency;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(accountRepositoryProvider).add(
            name: _nameCtrl.text.trim(),
            type: _type,
            currency: _currency,
            initialBalance: double.tryParse(_balanceCtrl.text) ?? 0,
            icon: _defaultIconFor(_type),
            color: _colorFor(_type),
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _defaultIconFor(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return 'wallet';
      case AccountType.card:
        return 'credit-card';
      case AccountType.bankAccount:
        return 'coins';
      case AccountType.eWallet:
        return 'wallet';
      case AccountType.crypto:
        return 'coins';
      case AccountType.investment:
        return 'trending-up';
      case AccountType.loan:
        return 'piggy-bank';
    }
  }

  static int _colorFor(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return 0xFF3DDC84;
      case AccountType.card:
        return 0xFF7C6CFF;
      case AccountType.bankAccount:
        return 0xFF8BD44A;
      case AccountType.eWallet:
        return 0xFFFFB74D;
      case AccountType.crypto:
        return 0xFFF7931A;
      case AccountType.investment:
        return 0xFF26C6DA;
      case AccountType.loan:
        return 0xFFE57373;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final base = ref.watch(settingsControllerProvider).baseCurrency;
    final isPro = ref.watch(proControllerProvider).isPro;

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: tr.newAccount,
          onBack: () => context.pop(),
        ),
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: tr.titleLabel),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _balanceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    labelText: tr.initialBalance,
                    hintText: '0',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_currency),
                  initialValue: uniqueAppCurrencies().any((c) => c.code == _currency)
                      ? _currency
                      : uniqueAppCurrencies().first.code,
                  items: [
                    for (final c in uniqueAppCurrencies())
                      DropdownMenuItem(
                        value: c.code,
                        child: Row(
                          children: [
                            Expanded(child: Text('${c.flag} ${c.code}')),
                            if (c.code != base && !isPro)
                              const ProBadge(dense: true, showLock: false),
                          ],
                        ),
                      ),
                  ],
                  decoration: InputDecoration(labelText: tr.currency),
                  onChanged: (v) async {
                    final next = v ?? _currency;
                    if (next != base &&
                        !await requirePro(context, ref, ProGate.currencies)) {
                      if (mounted) setState(() {});
                      return;
                    }
                    if (!mounted) return;
                    setState(() => _currency = next);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AccountType>(
            key: ValueKey(_type.index),
            initialValue: _type,
            items: [
              for (final t in AccountType.values)
                DropdownMenuItem(
                  value: t,
                  child: Text(tr.accountTypeLabel(t.index)),
                ),
            ],
            decoration: InputDecoration(labelText: tr.accountType),
            onChanged: (v) => setState(() => _type = v ?? AccountType.cash),
          ),
          const SizedBox(height: 28),
          ScaledElevatedButton(
            expand: true,
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '...' : tr.save),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
