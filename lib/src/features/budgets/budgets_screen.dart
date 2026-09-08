import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/date_format_ext.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import 'budget_period.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final budgetsAsync = ref.watch(budgetsProvider);
    final txsAsync = ref.watch(allTransactionsProvider);
    final budgets = budgetsAsync.valueOrNull ?? const [];
    final settings = ref.watch(settingsControllerProvider);
    final currency = settings.baseCurrency;

    final now = DateTime.now();
    final isPro = ref.watch(proControllerProvider).isPro;
    final activeBudgets = budgets
        .where((b) => isActiveBudget(endDate: b.endDate, now: now))
        .length;

    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final daysLeft = monthEnd.difference(DateTime.now()).inDays;

    void retryLoad() {
      ref.invalidate(budgetsProvider);
      ref.invalidate(allTransactionsProvider);
    }

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
              first: tr.budgets,
              subtitle: quotaLabel(
                isPro: isPro,
                used: activeBudgets,
                limit: ProLimits.budgets,
              ),
              onBack: () => context.pop(),
              action: RoundIconButton(
                icon: LucideIcons.plus,
                onTap: () async {
                  if (!await requireQuota(
                      context, ref, ProGate.budgets, activeBudgets)) {
                    return;
                  }
                  if (!context.mounted) return;
                  context.push('/budgets/new');
                },
              ),
            ),
        headerGap: 16,
        children: [
            Text(
              formatMonthYear(
                now,
                locale: Localizations.localeOf(context).languageCode,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: context.mutedText,
              ),
            ),
            const SizedBox(height: 12),
            AsyncValuesGate(
              values: [budgetsAsync, txsAsync],
              onRetry: retryLoad,
              child: Builder(
                builder: (context) {
                  final loadedBudgets = budgetsAsync.requireValue;
                  final allTxs = txsAsync.requireValue;

                  var totalSpent = 0.0;
                  var totalBudget = 0.0;
                  for (final b in loadedBudgets) {
                    if (!isActiveBudget(endDate: b.endDate, now: now)) {
                      continue;
                    }
                    final range = currentBudgetRange(b, now);
                    final catIds =
                        (jsonDecode(b.categoryIdsJson) as List).cast<int>();
                    final prev = previousBudgetRange(b, now);
                    final prevSpent =
                        budgetSpentInRange(allTxs, prev, categoryIds: catIds);
                    final limit = effectiveBudgetLimit(
                      budget: b,
                      previousSpent: prevSpent,
                    );
                    totalBudget += limit;
                    totalSpent +=
                        budgetSpentInRange(allTxs, range, categoryIds: catIds);
                  }

                  final progress = totalBudget > 0
                      ? (totalSpent / totalBudget).clamp(0, 1)
                      : 0;
                  final leftAmount =
                      (totalBudget - totalSpent).clamp(0, double.infinity);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Summary(
                        spent: totalSpent,
                        budget: totalBudget,
                        currency: currency,
                        progress: progress.toDouble(),
                        leftAmount: leftAmount.toDouble(),
                        daysLeft: daysLeft,
                      ),
                      const SizedBox(height: 20),
                      if (loadedBudgets.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              tr.emptyBudgetsTitle,
                              style: TextStyle(color: context.mutedText),
                            ),
                          ),
                        )
                      else
                        for (final b in loadedBudgets)
                          _BudgetItem(
                            budget: b,
                            allTxs: allTxs,
                          ),
                    ],
                  );
                },
              ),
            ),
          ],
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
          AppProgressBar(
            value: progress,
            height: 10,
            trackColor: Colors.white.withValues(alpha: 0.12),
            color: AppColors.lime,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Tr.of(context).percentUsed((progress * 100).round()),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${formatMoney(leftAmount, currency)} · ${Tr.of(context).daysLeftLabel(daysLeft)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () => context.push('/budgets/${budget.id}/edit'),
        child: SoftCard(
          padding: const EdgeInsets.all(16),
          radius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ColorWellIcon(
                    color: Color(budget.color),
                    icon: LucideIcons.pieChart,
                    size: 42,
                    iconSize: 18,
                    radius: 14,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatMoney(spent, budget.currency)} / ${formatMoney(limit, budget.currency)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: barColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppProgressBar(
                value: progress.toDouble(),
                height: 8,
                color: barColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

