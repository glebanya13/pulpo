import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const [];
    final settings = ref.watch(settingsControllerProvider);
    final currency = settings.baseCurrency;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final monthTxs = ref
            .watch(transactionsInRangeProvider(
                (start: monthStart, end: monthEnd)))
            .valueOrNull ??
        const [];

    var totalSpent = 0.0;
    for (final t in monthTxs) {
      if (TxType.values[t.type] == TxType.expense) totalSpent += t.amount;
    }

    var totalBudget = 0.0;
    for (final b in budgets) {
      totalBudget += b.amount;
    }

    final progress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0, 1) : 0;
    final leftAmount = (totalBudget - totalSpent).clamp(0, double.infinity);
    final daysLeft = monthEnd.difference(DateTime.now()).inDays;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.arrowLeft,
                        size: 18, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.budgets,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _openBudgetEditor(context, ref, existing: null),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.plus,
                        size: 18, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Text(
                DateFormat('MMMM yyyy',
                        Localizations.localeOf(context).languageCode)
                    .format(now),
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),
            _Summary(
              spent: totalSpent,
              budget: totalBudget,
              currency: currency,
              progress: progress.toDouble(),
              leftAmount: leftAmount.toDouble(),
              daysLeft: daysLeft,
            ),
            const SizedBox(height: 20),
            if (budgets.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(tr.emptyBudgetsTitle,
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              for (final b in budgets)
                _BudgetItem(
                  budget: b,
                  monthTxs: monthTxs,
                ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.spent,
    required this.budget,
    required this.currency,
    required this.progress,
    required this.leftAmount,
    required this.daysLeft,
  });
  final double spent;
  final double budget;
  final String currency;
  final double progress;
  final double leftAmount;
  final int daysLeft;

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
            Tr.of(context).spentThisMonth,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(spent, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text(
            Tr.of(context)
                .outOfBudgetTemplate
                .replaceFirst('{}', formatMoney(budget, currency)),
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.lime, AppColors.limeDark],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).round()}% использовано',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '${formatMoney(leftAmount, currency)} · $daysLeft дн.',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetItem extends ConsumerWidget {
  const _BudgetItem({required this.budget, required this.monthTxs});
  final db.Budget budget;
  final List monthTxs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catIds = (jsonDecode(budget.categoryIdsJson) as List).cast<int>();
    var spent = 0.0;
    for (final t in monthTxs) {
      if (TxType.values[t.type] != TxType.expense) continue;
      if (catIds.isNotEmpty && !catIds.contains(t.categoryId)) continue;
      spent += t.amount;
    }
    final progress = budget.amount > 0 ? (spent / budget.amount).clamp(0, 1) : 0;
    final barColor = progress > 0.9
        ? AppColors.danger
        : (progress > 0.7 ? AppColors.warning : AppColors.lime);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openBudgetEditor(context, ref, existing: budget),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(budget.color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.pieChart,
                    size: 16,
                    color: context.isDark ? Colors.white : AppColors.ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  budget.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.primaryText),
                ),
              ),
              Text(
                '${formatMoney(spent, budget.currency)} / ${formatMoney(budget.amount, budget.currency)}',
                style: TextStyle(
                    fontSize: 12, color: context.faintText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: context.progressTrack,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

Future<void> _openBudgetEditor(
  BuildContext context,
  WidgetRef ref, {
  required db.Budget? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final amountCtrl = TextEditingController(
      text: existing == null ? '' : existing.amount.toString());
  var period = existing?.period ?? 1; // 1 = month
  final isEdit = existing != null;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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
                child: Divider(thickness: 4, color: context.handleBar),
              ),
            ),
            const SizedBox(height: 12),
            Text(isEdit ? Tr.of(ctx).editBudget : Tr.of(ctx).newBudget,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration:
                  InputDecoration(labelText: Tr.of(ctx).budgetName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: Tr.of(ctx).amount),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: period,
              decoration:
                  InputDecoration(labelText: Tr.of(ctx).periodicity),
              items: [
                DropdownMenuItem(value: 0, child: Text(Tr.of(ctx).freqWeekly)),
                DropdownMenuItem(
                    value: 1, child: Text(Tr.of(ctx).monthlyLabel)),
                DropdownMenuItem(
                    value: 3, child: Text(Tr.of(ctx).yearlyLabel)),
              ],
              onChanged: (v) => setSt(() => period = v ?? 1),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty || amount <= 0) return;
                final repo = ref.read(budgetRepositoryProvider);
                if (isEdit) {
                  await repo.update(
                    id: existing.id,
                    name: nameCtrl.text.trim(),
                    amount: amount,
                    period: period,
                  );
                } else {
                  final currency =
                      ref.read(settingsControllerProvider).baseCurrency;
                  await repo.add(
                    name: nameCtrl.text.trim(),
                    amount: amount,
                    currency: currency,
                    period: period,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(Tr.of(ctx).save),
            ),
            if (isEdit) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: ctx,
                    builder: (dctx) => AlertDialog(
                      title: Text(Tr.of(dctx).deleteBudgetTitle),
                      content: Text(Tr.of(dctx).deleteTxBody),
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
                      .read(budgetRepositoryProvider)
                      .delete(existing.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE53E3E),
                ),
                child: Text(Tr.of(ctx).delete),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
