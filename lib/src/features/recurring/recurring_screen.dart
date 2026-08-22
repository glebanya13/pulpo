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
import '../../data/repositories/providers.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/app_bottom_sheet.dart';
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(
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
            const SizedBox(height: 16),
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
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final rules = ref.read(recurringRulesProvider).valueOrNull ?? const [];
    final used = rules.where((r) => !r.isPaused).length;
    if (!await requireQuota(context, ref, ProGate.recurring, used)) return;
    if (!context.mounted) return;
    await _openRuleEditor(context, ref, existing: null);
  }
}

Future<void> _openRuleEditor(
  BuildContext context,
  WidgetRef ref, {
  required db.RecurringRule? existing,
}) async {
  final template = existing == null
      ? null
      : RecurringTemplate.fromJson(existing.templateJson);
  final nameCtrl = TextEditingController(text: template?.name ?? '');
  final amountCtrl = TextEditingController(
      text: template == null ? '' : template.amount.toString());
  var frequency = existing?.frequency ?? 'monthly';
  var type = template?.type ?? TxType.expense;
  DateTime next =
      existing?.nextRunAt ?? DateTime.now().add(const Duration(days: 7));
  final isEdit = existing != null;

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
            Text(isEdit ? Tr.of(ctx).editRule : Tr.of(ctx).newRule,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TabsPill(
              tabs: [Tr.of(ctx).expense, Tr.of(ctx).income],
              index: type == TxType.expense ? 0 : 1,
              onChanged: (i) => setSt(() {
                type = i == 0 ? TxType.expense : TxType.income;
              }),
              limeActive: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration:
                  InputDecoration(labelText: Tr.of(ctx).titleLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: Tr.of(ctx).amount),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: frequency,
              decoration:
                  InputDecoration(labelText: Tr.of(ctx).frequencyLabel),
              items: [
                DropdownMenuItem(
                    value: 'daily', child: Text(Tr.of(ctx).freqDaily)),
                DropdownMenuItem(
                    value: 'weekly', child: Text(Tr.of(ctx).freqWeekly)),
                DropdownMenuItem(
                    value: 'monthly', child: Text(Tr.of(ctx).monthlyLabel)),
                DropdownMenuItem(
                    value: 'yearly', child: Text(Tr.of(ctx).yearlyLabel)),
              ],
              onChanged: (v) => setSt(() => frequency = v ?? 'monthly'),
            ),
            const SizedBox(height: 12),
            Pressable(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: next,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365)),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 3)),
                );
                if (picked != null) setSt(() => next = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: ctx.scaffoldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar,
                        size: 18, color: ctx.primaryText),
                    const SizedBox(width: 10),
                    Text(
                        '${Tr.of(ctx).nextRunPrefix}${DateFormat('d MMM y', Localizations.localeOf(ctx).languageCode).format(next)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ScaledElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty || amount <= 0) return;
                final accounts =
                    ref.read(accountsProvider).valueOrNull ?? const [];
                if (accounts.isEmpty) return;
                final repo = ref.read(recurringRepositoryProvider);
                if (isEdit) {
                  await repo.update(
                    id: existing.id,
                    name: nameCtrl.text.trim(),
                    accountId: template!.accountId,
                    categoryId: template.categoryId,
                    amount: amount,
                    currency: template.currency,
                    type: type,
                    frequency: frequency,
                    nextRun: next,
                  );
                } else {
                  await repo.add(
                    name: nameCtrl.text.trim(),
                    accountId: accounts.first.id,
                    amount: amount,
                    currency: accounts.first.currency,
                    type: type,
                    frequency: frequency,
                    nextRun: next,
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
                      title: Text(Tr.of(dctx).deleteRuleTitle),
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
                      .read(recurringRepositoryProvider)
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
      onTap: () => _openRuleEditor(context, ref, existing: rule),
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
                      ? AppColors.limeAccent
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
