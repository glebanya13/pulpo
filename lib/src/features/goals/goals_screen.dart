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
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final goalsAsync = ref.watch(goalsProvider);
    final goals = goalsAsync.valueOrNull ?? const [];
    final active =
        goals.where((g) => isActiveGoal(isCompleted: g.isCompleted)).length;
    final isPro = ref.watch(proControllerProvider).isPro;
    final currency = ref.watch(settingsControllerProvider).baseCurrency;

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
              first: tr.goals,
              subtitle: quotaLabel(
                  isPro: isPro, used: active, limit: ProLimits.goals),
              onBack: () => context.pop(),
              action: RoundIconButton(
                icon: LucideIcons.plus,
                onTap: () async {
                  if (!await requireQuota(
                      context, ref, ProGate.goals, active)) {
                    return;
                  }
                  if (!context.mounted) return;
                  context.push('/goals/new');
                },
              ),
            ),
        headerGap: 16,
        children: [
            AsyncValuesGate(
              values: [goalsAsync],
              onRetry: () => ref.invalidate(goalsProvider),
              child: Builder(
                builder: (context) {
                  final loaded = goalsAsync.requireValue;
                  if (loaded.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.target,
                      title: tr.goalsEmptyTitle,
                      description: tr.goalsEmptyDesc,
                    );
                  }
                  return Column(
                    children: [
                      for (final g in loaded)
                        _GoalCard(
                          goal: g,
                          fallbackCurrency: currency,
                          onAdd: () =>
                              context.push('/goals/${g.id}/progress'),
                          onEdit: () =>
                              context.push('/goals/${g.id}/edit'),
                          onDelete: () async {
                            await ref
                                .read(goalRepositoryProvider)
                                .delete(g.id);
                          },
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.fallbackCurrency,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final db.Goal goal;
  final String fallbackCurrency;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final currency = goal.currency.isEmpty ? fallbackCurrency : goal.currency;
    final p = goal.targetAmount <= 0
        ? 0.0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Pressable(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(LucideIcons.pencil,
                        size: 16, color: context.mutedText),
                  ),
                ),
                Pressable(
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(LucideIcons.trash2,
                        size: 16, color: AppColors.danger),
                  ),
                ),
              ],
            ),
            Text(
              '${formatMoney(goal.currentAmount, currency)} / ${formatMoney(goal.targetAmount, currency)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.mutedText,
              ),
            ),
            if (goal.targetDate != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMM yyyy', locale).format(goal.targetDate!),
                style: TextStyle(fontSize: 12, color: context.faintText),
              ),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 8,
                backgroundColor: context.progressTrack,
                color: Color(goal.color),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ScaledTextButton(
                onPressed: onAdd,
                child: Text(tr.addToGoal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


