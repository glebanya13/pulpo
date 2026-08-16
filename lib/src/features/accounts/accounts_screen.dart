import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final balances = ref.watch(accountBalancesProvider);
    final total = ref.watch(totalBalanceProvider);
    final currency = ref.watch(settingsControllerProvider).baseCurrency;

    final bankLike = accounts.where((a) {
      final t = AccountType.values[a.type];
      return t == AccountType.bankAccount ||
          t == AccountType.card ||
          t == AccountType.investment;
    }).toList();
    final cashLike = accounts.where((a) {
      final t = AccountType.values[a.type];
      return t == AccountType.cash ||
          t == AccountType.eWallet ||
          t == AccountType.crypto ||
          t == AccountType.loan;
    }).toList();
    final currencies =
        accounts.map((a) => a.currency).toSet().length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(
              first: tr.myAccounts,
              subtitle:
                  '${accounts.length} ${tr.accountsCountLabel} · $currencies ${tr.currency.toLowerCase()}',
              onBack: () => context.pop(),
              action: RoundIconButton(
                icon: LucideIcons.plus,
                onTap: () => _openAddAccount(context, ref),
              ),
            ),
            const SizedBox(height: 16),
            _NetWorthCard(value: total, currency: currency),
            const SizedBox(height: 16),
            if (bankLike.isNotEmpty) ...[
              SectTitle(title: tr.bankAccounts),
              for (final a in bankLike)
                _AccountCard(
                  account: a,
                  balance: balances[a.id] ?? 0,
                ),
            ],
            if (cashLike.isNotEmpty) ...[
              SectTitle(title: tr.cashWallets),
              for (final a in cashLike)
                _AccountCard(
                  account: a,
                  balance: balances[a.id] ?? 0,
                ),
            ],
            const SizedBox(height: 12),
            _AddCard(onTap: () => _openAddAccount(context, ref)),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddAccount(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    AccountType type = AccountType.cash;
    String currency = ref.read(settingsControllerProvider).baseCurrency;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.handleBar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  Tr.of(context).newAccount,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration:
                      InputDecoration(labelText: Tr.of(context).titleLabel),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: balanceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: Tr.of(context).initialBalance,
                          hintText: '0',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: currency,
                        items: const [
                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          DropdownMenuItem(value: 'MXN', child: Text('MXN')),
                          DropdownMenuItem(value: 'ARS', child: Text('ARS')),
                          DropdownMenuItem(value: 'COP', child: Text('COP')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                        ],
                        decoration:
                            InputDecoration(labelText: Tr.of(context).currency),
                        onChanged: (v) => setState(() => currency = v ?? 'EUR'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AccountType>(
                  initialValue: type,
                  items: [
                    for (final t in AccountType.values)
                      DropdownMenuItem(
                        value: t,
                        child: Text(Tr.of(context).accountTypeLabel(t.index)),
                      ),
                  ],
                  decoration:
                      InputDecoration(labelText: Tr.of(context).accountType),
                  onChanged: (v) => setState(() => type = v ?? AccountType.cash),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await ref.read(accountRepositoryProvider).add(
                          name: nameCtrl.text.trim(),
                          type: type,
                          currency: currency,
                          initialBalance:
                              double.tryParse(balanceCtrl.text) ?? 0,
                          icon: _defaultIconFor(type),
                          color: _colorFor(type),
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(Tr.of(context).save),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      },
    );
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
        return 0xFFD4F5E0;
      case AccountType.card:
        return 0xFFE8E4FF;
      case AccountType.bankAccount:
        return 0x40CDFF3A;
      case AccountType.eWallet:
        return 0xFFE0F2FE;
      case AccountType.crypto:
        return 0xFFFFF3D6;
      case AccountType.investment:
        return 0x40CDFF3A;
      case AccountType.loan:
        return 0xFFFFE4E1;
    }
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.value, required this.currency});
  final double value;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.emphasized,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.emphasizedBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Tr.of(context).netWorth,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(value, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '↑ в реальном времени',
              style: TextStyle(
                color: AppColors.lime,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.balance});
  final db.Account account;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/accounts/${account.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(account.color),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(lucideByKey(account.icon),
                    size: 22, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.primaryText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Tr.of(context).accountTypeLabel(account.type)} · ${account.currency}',
                      style: TextStyle(
                          fontSize: 11, color: context.faintText),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(balance, account.currency),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: balance < 0
                          ? AppColors.danger
                          : context.primaryText,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (account.creditLimit != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${Tr.of(context).creditLimitPrefix}${formatMoney(account.creditLimit!, account.currency)}',
                        style: TextStyle(
                            fontSize: 11, color: context.faintText),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFCCCCCC),
            width: 1.5,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.scaffoldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(LucideIcons.plus, color: context.faintText),
              ),
              const SizedBox(width: 14),
              Text(
                Tr.of(context).addAccount,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.faintText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
