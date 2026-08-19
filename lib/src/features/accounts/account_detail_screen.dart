import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/pressable.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final account = ref.watch(accountByIdProvider(accountId));
    final balances = ref.watch(accountBalancesProvider);
    final allTxs = ref.watch(allTransactionsProvider).valueOrNull ?? const [];
    final txs = allTxs.where((t) => t.accountId == accountId).toList();

    if (account == null) {
      return Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
          child: Text('${tr.account} · —',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    // 12 недель истории
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtn(
                    icon: LucideIcons.arrowLeft, onTap: () => context.pop()),
                Text(tr.account,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                _CircleBtn(
                    icon: LucideIcons.pencil,
                    onTap: () =>
                        _openAccountEditor(context, ref, existing: account)),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ColorWellIcon(
                color: Color(account.color),
                icon: lucideByKey(account.icon),
                size: 64,
                iconSize: 28,
                radius: 20,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(account.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${tr.accountTypeLabel(account.type)} · ${account.currency}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                formatMoney(balances[account.id] ?? 0, account.currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.history12Weeks,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 70,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: tr.income,
                    value: formatMoney(income, account.currency),
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: tr.expense,
                    value: formatMoney(expense, account.currency),
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr.recentTransactions,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text(tr.seeAll,
                    style: const TextStyle(
                        color: AppColors.lime,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(tr.emptyTransactionsList,
                      style: const TextStyle(color: Colors.white54)),
                ),
              )
            else
              for (final t in recent)
                Theme(
                  data: Theme.of(context).copyWith(
                    cardTheme: const CardThemeData(color: Color(0xFF1A1A1A)),
                  ),
                  child: _DarkTxRow(tx: t),
                ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () =>
                        _openAccountEditor(context, ref, existing: account),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.center,
                      child: Text(tr.edit,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

Future<void> _openAccountEditor(
  BuildContext context,
  WidgetRef ref, {
  required db.Account existing,
}) async {
  final nameCtrl = TextEditingController(text: existing.name);
  var includeInTotal = existing.includeInTotal;

  await showAppBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: 36,
                child: Divider(thickness: 4, color: ctx.handleBar),
              ),
            ),
            const SizedBox(height: 12),
            Text(Tr.of(ctx).editAccount,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration:
                  InputDecoration(labelText: Tr.of(ctx).accountName),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: includeInTotal,
              onChanged: (v) => setSt(() => includeInTotal = v),
              title: Text(Tr.of(ctx).includeInTotal),
            ),
            const SizedBox(height: 12),
            ScaledElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await ref.read(accountRepositoryProvider).update(
                      id: existing.id,
                      name: nameCtrl.text.trim(),
                      includeInTotal: includeInTotal,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(Tr.of(ctx).save),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (dctx) => AlertDialog(
                    title: Text(Tr.of(dctx).deleteAccountTitle),
                    content: Text(Tr.of(dctx).deleteAccountBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: Text(Tr.of(dctx).cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE53E3E),
                        ),
                        child: Text(Tr.of(dctx).delete),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                await ref
                    .read(accountRepositoryProvider)
                    .delete(existing.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (context.mounted) context.pop();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE53E3E),
              ),
              child: Text(Tr.of(ctx).delete),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DarkTxRow extends ConsumerWidget {
  const _DarkTxRow({required this.tx});
  final dynamic tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(categoryByIdProvider(tx.categoryId));
    final type = TxType.values[tx.type];
    final isIncome = type == TxType.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              cat != null ? lucideByKey(cat.icon) : LucideIcons.circle,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('d MMM',
                          Localizations.localeOf(context).languageCode)
                      .format(tx.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            (isIncome ? '+' : '−') + formatMoney(tx.amount, tx.currency),
            style: TextStyle(
              color: isIncome
                  ? AppColors.lime
                  : type == TxType.expense
                      ? AppColors.danger
                      : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
