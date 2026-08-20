import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/pressable.dart';
import 'budget_period.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const [];
    final settings = ref.watch(settingsControllerProvider);
    final currency = settings.baseCurrency;

    final now = DateTime.now();
    final allTxs =
        ref.watch(allTransactionsProvider).valueOrNull ?? const [];

    var totalSpent = 0.0;
    var totalBudget = 0.0;
    for (final b in budgets) {
      if (!isActiveBudget(endDate: b.endDate, now: now)) continue;
      final range = currentBudgetRange(b, now);
      final catIds = (jsonDecode(b.categoryIdsJson) as List).cast<int>();
      final prev = previousBudgetRange(b, now);
      final prevSpent = budgetSpentInRange(allTxs, prev, categoryIds: catIds);
      final limit = effectiveBudgetLimit(budget: b, previousSpent: prevSpent);
      totalBudget += limit;
      totalSpent += budgetSpentInRange(allTxs, range, categoryIds: catIds);
    }

    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final progress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0, 1) : 0;
    final leftAmount = (totalBudget - totalSpent).clamp(0, double.infinity);
    final daysLeft = monthEnd.difference(DateTime.now()).inDays;
    final isPro = ref.watch(proControllerProvider).isPro;
    final activeBudgets = budgets
        .where((b) => isActiveBudget(endDate: b.endDate, now: now))
        .length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                Pressable(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.arrowLeft,
                        size: 18, color: context.primaryText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.budgets,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: context.primaryText,
                        ),
                      ),
                      Text(
                        quotaLabel(
                          isPro: isPro,
                          used: activeBudgets,
                          limit: ProLimits.budgets,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Pressable(
                  onTap: () async {
                    if (!await requireQuota(
                        context, ref, ProGate.budgets, activeBudgets)) {
                      return;
                    }
                    if (!context.mounted) return;
                    await _openBudgetEditor(context, ref, existing: null);
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.plus,
                        size: 18, color: context.primaryText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Text(
                DateFormat('LLLL yyyy',
                        Localizations.localeOf(context).languageCode)
                    .format(now),
                style: TextStyle(color: context.mutedText),
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
                  color: context.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(tr.emptyBudgetsTitle,
                      style: TextStyle(color: context.mutedText)),
                ),
              )
            else
              for (final b in budgets)
                _BudgetItem(
                  budget: b,
                  allTxs: allTxs,
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
                Tr.of(context).percentUsed((progress * 100).round()),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '${formatMoney(leftAmount, currency)} · ${Tr.of(context).daysLeftLabel(daysLeft)}',
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
  const _BudgetItem({required this.budget, required this.allTxs});
  final db.Budget budget;
  final List allTxs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final catIds = (jsonDecode(budget.categoryIdsJson) as List).cast<int>();
    final range = currentBudgetRange(budget, now);
    final prev = previousBudgetRange(budget, now);
    final prevSpent =
        budgetSpentInRange(allTxs, prev, categoryIds: catIds);
    final limit =
        effectiveBudgetLimit(budget: budget, previousSpent: prevSpent);
    final spent =
        budgetSpentInRange(allTxs, range, categoryIds: catIds);
    final progress = limit > 0 ? (spent / limit).clamp(0, 1) : 0;
    final barColor = progress > 0.9
        ? AppColors.danger
        : (progress > 0.7 ? AppColors.warning : AppColors.lime);

    return Pressable(
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
              ColorWellIcon(
                color: Color(budget.color),
                icon: LucideIcons.pieChart,
                size: 36,
                iconSize: 16,
                radius: 12,
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
                '${formatMoney(spent, budget.currency)} / ${formatMoney(limit, budget.currency)}',
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
  var period = existing?.period ?? 1;
  var rollover = existing?.rollover ?? false;
  var selectedCats = existing == null
      ? <int>{}
      : (jsonDecode(existing.categoryIdsJson) as List).cast<int>().toSet();
  final isEdit = existing != null;
  final expenseCats = (ref.read(categoriesProvider).valueOrNull ?? const [])
      .where((c) =>
          CategoryType.values[c.type] == CategoryType.expense ||
          CategoryType.values[c.type] == CategoryType.both)
      .toList();

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
            const SizedBox(height: 12),
            Text(Tr.of(ctx).budgetCategories,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.mutedText)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                FilterChip(
                  label: Text(Tr.of(ctx).budgetCategoriesAll),
                  selected: selectedCats.isEmpty,
                  onSelected: (_) => setSt(() => selectedCats.clear()),
                ),
                for (final c in expenseCats)
                  FilterChip(
                    label: Text(Tr.of(ctx).categoryName(c.name)),
                    selected: selectedCats.contains(c.id),
                    onSelected: (on) => setSt(() {
                      if (on) {
                        selectedCats.add(c.id);
                      } else {
                        selectedCats.remove(c.id);
                      }
                    }),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: rollover,
              onChanged: (v) => setSt(() => rollover = v),
              title: Text(Tr.of(ctx).budgetRollover),
              subtitle: Text(Tr.of(ctx).budgetRolloverDesc),
            ),
            const SizedBox(height: 12),
            ScaledElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty || amount <= 0) return;
                final repo = ref.read(budgetRepositoryProvider);
                final catList = selectedCats.toList();
                if (isEdit) {
                  await repo.update(
                    id: existing.id,
                    name: nameCtrl.text.trim(),
                    amount: amount,
                    period: period,
                    categoryIds: catList,
                    rollover: rollover,
                  );
                } else {
                  final currency =
                      ref.read(settingsControllerProvider).baseCurrency;
                  await repo.add(
                    name: nameCtrl.text.trim(),
                    amount: amount,
                    currency: currency,
                    period: period,
                    categoryIds: catList,
                    rollover: rollover,
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
