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
import '../../data/repositories/recurring_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final rulesAsync = ref.watch(recurringRulesProvider);
    final rules = rulesAsync.valueOrNull ?? const [];
    final active = rules.where((r) => !r.isPaused).toList();
    final isPro = ref.watch(proControllerProvider).isPro;

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
              first: tr.recurringOps,
              subtitle: quotaLabel(
                  isPro: isPro,
                  used: active.length,
                  limit: ProLimits.recurring),
              onBack: () => context.pop(),
              action: RoundIconButton(
                icon: LucideIcons.plus,
                onTap: () => _openAdd(context),
              ),
            ),
        headerGap: 16,
        children: [
            AsyncValuesGate(
              values: [rulesAsync],
              onRetry: () => ref.invalidate(recurringRulesProvider),
              child: Builder(
                builder: (context) {
                  final loaded = rulesAsync.requireValue;
                  final activeLoaded =
                      loaded.where((r) => !r.isPaused).toList();
                  final paused =
                      loaded.where((r) => r.isPaused).toList();
                  final current = _tab == 1 ? paused : activeLoaded;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TabsPill(
                        tabs: [tr.activeTab, tr.pausedTab],
                        index: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                      const SizedBox(height: 16),
                      if (current.isEmpty)
                        EmptyState(
                          icon: LucideIcons.repeat,
                          title: tr.rulesEmptyTitle,
                          description: tr.rulesEmptyDesc,
                        )
                      else
                        for (final r in current) _RuleCard(rule: r),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final rules = ref.read(recurringRulesProvider).valueOrNull ?? const [];
    final used = rules.where((r) => !r.isPaused).length;
    if (!await requireQuota(context, ref, ProGate.recurring, used)) return;
    if (!context.mounted) return;
    context.push('/recurring/new');
  }
}

class _RuleCard extends ConsumerWidget {
  const _RuleCard({required this.rule});
  final db.RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final template = RecurringTemplate.fromJson(rule.templateJson);
    final daysUntil = rule.nextRunAt.difference(DateTime.now()).inDays;

    return Pressable(
      onTap: () => context.push('/recurring/${rule.id}/edit'),
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
                size: 40,
                iconSize: 18,
                radius: 14,
                color: template.type == TxType.income
                    ? AppColors.bgFood
                    : const Color(0xFFE8E4FF),
                icon: template.type == TxType.income
                    ? LucideIcons.trendingUp
                    : LucideIcons.repeat,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.primaryText)),
                    const SizedBox(height: 2),
                    Text(
                      _freqLabel(rule.frequency, tr),
                      style: TextStyle(
                          fontSize: 11, color: context.faintText),
                    ),
                  ],
                ),
              ),
              Text(
                (template.type == TxType.expense ? '−' : '+') +
                    formatMoney(template.amount, template.currency),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: template.type == TxType.income
                      ? context.accent
                      : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${tr.nextRunPrefix}${DateFormat('d MMM', locale).format(rule.nextRunAt)}',
                    style: TextStyle(
                        fontSize: 11, color: context.faintText),
                  ),
                  const SizedBox(width: 6),
                  if (daysUntil >= 0)
                    BudgetBadge(
                      text: tr.inDays(daysUntil),
                      tone:
                          daysUntil <= 3 ? BadgeTone.red : BadgeTone.orange,
                    ),
                ],
              ),
              Pressable(
                onTap: () async {
                  if (rule.isPaused) {
                    final rules =
                        ref.read(recurringRulesProvider).valueOrNull ?? const [];
                    final used = rules.where((r) => !r.isPaused).length;
                    if (!await requireQuota(
                        context, ref, ProGate.recurring, used)) {
                      return;
                    }
                  }
                  await ref
                      .read(recurringRepositoryProvider)
                      .togglePause(rule.id, !rule.isPaused);
                },
                child: Icon(
                  rule.isPaused ? LucideIcons.play : LucideIcons.pause,
                  size: 16,
                  color: context.faintText,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  String _freqLabel(String f, Tr tr) {
    switch (f) {
      case 'daily':
        return tr.freqDaily;
      case 'weekly':
        return tr.freqWeekly;
      case 'monthly':
        return tr.monthlyLabel;
      case 'yearly':
        return tr.yearlyLabel;
      default:
        return f;
    }
  }
}
