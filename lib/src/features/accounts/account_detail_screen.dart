import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/color_well.dart';
import '../../core/theme/liquid_glass.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final accountsAsync = ref.watch(accountsProvider);
    final txsAsync = ref.watch(allTransactionsProvider);

    return AsyncValuesGate(
      values: [accountsAsync, txsAsync],
      onRetry: () {
        ref.invalidate(accountsProvider);
        ref.invalidate(allTransactionsProvider);
      },
      child: Builder(
        builder: (context) {
          final account = ref.watch(accountByIdProvider(accountId));
          final balances = ref.watch(accountBalancesProvider);
          final allTxs = txsAsync.requireValue;
          final txs =
              allTxs.where((t) => t.accountId == accountId).toList();

          if (account == null) {
            return Scaffold(
              backgroundColor: AppColors.ink,
              body: Center(
                child: Text(
                  '${tr.account} · —',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          return _AccountDetailBody(
            tr: tr,
            account: account,
            balances: balances,
            allTxs: allTxs,
            txs: txs,
            accountId: accountId,
          );
        },
      ),
    );
  }
}

class _AccountDetailBody extends ConsumerWidget {
  const _AccountDetailBody({
    required this.tr,
    required this.account,
    required this.balances,
    required this.allTxs,
    required this.txs,
    required this.accountId,
  });

  final Tr tr;
  final db.Account account;
  final Map<int, double> balances;
  final List<db.Transaction> allTxs;
  final List<db.Transaction> txs;
  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(
      settingsControllerProvider.select((s) => s.hideBalances),
    );
    final now = DateTime.now();
    final weeks = <double>[];
    var running = account.initialBalance;
    final sortedAsc = [...allTxs]..sort((a, b) => a.date.compareTo(b.date));
    for (var i = 11; i >= 0; i--) {
      final weekEnd = now.subtract(Duration(days: i * 7));
      var bal = account.initialBalance;
      for (final t in sortedAsc) {
        if (t.accountId != account.id) continue;
        if (t.date.isAfter(weekEnd)) break;
        final type = TxType.values[t.type];
        if (type == TxType.income) bal += t.amount;
        if (type == TxType.expense) bal -= t.amount;
        if (type == TxType.transfer) bal -= t.amount;
      }
      running = bal;
      weeks.add(running);
    }
    final maxBal = weeks.fold<double>(0, (a, b) => b > a ? b : a);

    // Месячные income/expense
    final monthStart = DateTime(now.year, now.month, 1);
    var income = 0.0;
    var expense = 0.0;
    for (final t in txs) {
      if (t.date.isBefore(monthStart)) continue;
      final type = TxType.values[t.type];
      if (type == TxType.income) income += t.amount;
      if (type == TxType.expense) expense += t.amount;
    }

    final recent = txs.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: StickyScrollPage(
        header: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtn(
                    icon: LucideIcons.arrowLeft, onTap: () => context.pop()),
                LiquidGlass(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(tr.account,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
                _CircleBtn(
                    icon: LucideIcons.pencil,
                    onTap: () =>
                        context.push('/accounts/${account.id}/edit')),
              ],
            ),
        headerGap: 16,
        children: [
            Center(
              child: ColorWellIcon(
                color: Color(account.color),
                icon: lucideByKey(account.icon),
                size: 48,
                iconSize: 22,
                radius: 14,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(account.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                '${tr.accountTypeLabel(account.type)} · ${account.currency}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        hidden
                            ? kMaskedMoney
                            : formatMoney(
                                balances[account.id] ?? 0,
                                account.currency,
                              ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: () => ref
                        .read(settingsControllerProvider.notifier)
                        .setHideBalances(!hidden),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.history12Weeks,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < weeks.length; i++)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
                              child: FractionallySizedBox(
                                heightFactor: maxBal > 0
                                    ? (weeks[i] / maxBal).clamp(0.05, 1)
                                    : 0.05,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.lime.withValues(
                                        alpha: 0.2 + (0.6 * (i / 11))),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: tr.income,
                    value: formatMoney(income, account.currency),
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: tr.expense,
                    value: formatMoney(expense, account.currency),
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr.recentTransactions,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Pressable(
                  onTap: () => context.push(
                    '/accounts/$accountId/transactions',
                  ),
                  child: Text(tr.seeAll,
                      style: const TextStyle(
                          color: AppColors.lime,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(tr.emptyTransactionsList,
                      style: const TextStyle(color: Colors.white54)),
                ),
              )
            else
              for (final t in recent)
                Pressable(
                  onTap: () => context.push('/tx/${t.id}'),
                  child: _DarkTxRow(tx: t),
                ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () =>
                        context.push('/accounts/${account.id}/edit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.center,
                      child: Text(tr.edit,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: RoundIconButton.chromeFill(context, onDarkMedia: true),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: RoundIconButton.chromeIcon(context, onDarkMedia: true),
        ),
      ),
    );
  }
}

class _MiniStat extends ConsumerWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(
      settingsControllerProvider.select((s) => s.hideBalances),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
              Pressable(
                onTap: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setHideBalances(!hidden),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 14,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                hidden ? kMaskedMoney : value,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _DarkTxRow extends ConsumerWidget {
  const _DarkTxRow({required this.tx});
  final dynamic tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(categoryByIdProvider(tx.categoryId));
    final type = TxType.values[tx.type];
    final isIncome = type == TxType.income;
    final hidden = ref.watch(
      settingsControllerProvider.select((s) => s.hideBalances),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              cat != null ? lucideByKey(cat.icon) : LucideIcons.circle,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note?.isNotEmpty == true
                      ? tx.note!
                      : (cat?.name ?? Tr.of(context).transactionSingular),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('d MMM',
                          Localizations.localeOf(context).languageCode)
                      .format(tx.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            hidden
                ? kMaskedMoney
                : (isIncome ? '+' : '−') +
                    formatMoney(tx.amount, tx.currency),
            style: TextStyle(
              color: isIncome
                  ? AppColors.lime
                  : type == TxType.expense
                      ? AppColors.danger
                      : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
