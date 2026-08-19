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
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final goals = ref.watch(goalsProvider).valueOrNull ?? const [];
    final active = goals.where((g) => isActiveGoal(isCompleted: g.isCompleted)).length;
    final isPro = ref.watch(proControllerProvider).isPro;
    final currency = ref.watch(settingsControllerProvider).baseCurrency;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(
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
                  await _openGoalEditor(context, ref, existing: null);
                },
              ),
            ),
            const SizedBox(height: 16),
            if (goals.isEmpty)
              EmptyState(
                icon: LucideIcons.target,
                title: tr.goalsEmptyTitle,
                description: tr.goalsEmptyDesc,
              )
            else
              for (final g in goals)
                _GoalCard(
                  goal: g,
                  fallbackCurrency: currency,
                  onAdd: () => _openProgress(context, ref, g),
                  onEdit: () =>
                      _openGoalEditor(context, ref, existing: g),
                  onDelete: () async {
                    await ref.read(goalRepositoryProvider).delete(g.id);
                  },
                ),
          ],
        ),
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

Future<void> _openProgress(
  BuildContext context,
  WidgetRef ref,
  db.Goal goal,
) async {
  final amountCtrl = TextEditingController();
  final accounts = ref.read(accountsProvider).valueOrNull ?? const [];
  var accountId = goal.accountId ??
      (accounts.isNotEmpty ? accounts.first.id : null);

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
            Text(Tr.of(ctx).addToGoal,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: Tr.of(ctx).amount),
            ),
            if (accounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: accountId,
                decoration:
                    InputDecoration(labelText: Tr.of(ctx).transferFrom),
                items: [
                  for (final a in accounts)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setSt(() => accountId = v),
              ),
            ],
            const SizedBox(height: 16),
            ScaledFilledButton(
              onPressed: () async {
                final v =
                    double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                if (v == null || v <= 0 || accountId == null) return;
                await ref.read(goalRepositoryProvider).addProgress(
                      id: goal.id,
                      amount: v,
                      accountId: accountId!,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(Tr.of(ctx).save),
            ),
          ],
        ),
      ),
    ),
  );
  amountCtrl.dispose();
}

Future<void> _openGoalEditor(
  BuildContext context,
  WidgetRef ref, {
  required db.Goal? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final targetCtrl = TextEditingController(
      text: existing == null ? '' : existing.targetAmount.toString());
  final currentCtrl = TextEditingController(
      text: existing == null ? '' : existing.currentAmount.toString());
  DateTime? targetDate = existing?.targetDate;
  final isEdit = existing != null;
  final currency = ref.read(settingsControllerProvider).baseCurrency;

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
            Text(isEdit ? Tr.of(ctx).editGoal : Tr.of(ctx).newGoal,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: Tr.of(ctx).goalName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: Tr.of(ctx).goalTarget),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currentCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: Tr.of(ctx).goalSaved),
            ),
            const SizedBox(height: 12),
            Pressable(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: targetDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setSt(() => targetDate = picked);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  targetDate == null
                      ? Tr.of(ctx).select
                      : DateFormat.yMMMd(
                              Localizations.localeOf(ctx).languageCode)
                          .format(targetDate!),
                  style: TextStyle(color: context.primaryText),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ScaledFilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final target =
                    double.tryParse(targetCtrl.text.replaceAll(',', '.'));
                if (name.isEmpty || target == null || target <= 0) return;
                final current =
                    double.tryParse(currentCtrl.text.replaceAll(',', '.')) ??
                        0;
                final repo = ref.read(goalRepositoryProvider);
                if (isEdit) {
                  await repo.update(
                    id: existing.id,
                    name: name,
                    targetAmount: target,
                    currentAmount: current,
                    targetDate: targetDate,
                    clearTargetDate: targetDate == null,
                  );
                } else {
                  await repo.add(
                    name: name,
                    targetAmount: target,
                    currency: currency,
                    currentAmount: current,
                    targetDate: targetDate,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(Tr.of(ctx).save),
            ),
          ],
        ),
      ),
    ),
  );
  nameCtrl.dispose();
  targetCtrl.dispose();
  currentCtrl.dispose();
}
