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
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final debts = ref.watch(debtsProvider).valueOrNull ?? const [];
    final currency = ref.watch(settingsControllerProvider).baseCurrency;

    final iOwe = debts.where((d) => d.direction == DebtDirection.iOwe.index);
    final owedToMe =
        debts.where((d) => d.direction == DebtDirection.owedToMe.index);

    final iOweSum = iOwe.fold<double>(0, (a, d) => a + (d.amount - d.paidAmount));
    final owedToMeSum =
        owedToMe.fold<double>(0, (a, d) => a + (d.amount - d.paidAmount));

    List<db.Debt> filtered;
    if (_tab == 1) {
      filtered = iOwe.toList();
    } else if (_tab == 2) {
      filtered = owedToMe.toList();
    } else {
      filtered = debts.toList();
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(
              first: tr.debts,
              subtitle: tr.activeCount(debts.length),
              onBack: () => context.pop(),
              action: RoundIconButton(
                icon: LucideIcons.plus,
                onTap: () => _openAdd(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: tr.iOwe,
                    value: formatMoney(iOweSum, currency),
                    color: AppColors.danger,
                    subtitle: tr.peopleCount(iOwe.length),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: tr.owedToMe,
                    value: formatMoney(owedToMeSum, currency),
                    color: AppColors.limeAccent,
                    subtitle: tr.peopleCount(owedToMe.length),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TabsPill(
              tabs: [tr.all, tr.iOwe, tr.owedToMe],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              EmptyState(
                icon: LucideIcons.users,
                title: tr.debtsEmptyTitle,
                description: tr.debtsEmptyDesc,
              )
            else
              for (final d in filtered) _DebtCard(debt: d),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) =>
      _openDebtEditor(context, ref, existing: null);
}

Future<void> _openDebtEditor(
  BuildContext context,
  WidgetRef ref, {
  required db.Debt? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.counterparty ?? '');
  final amountCtrl = TextEditingController(
      text: existing == null ? '' : existing.amount.toString());
  var direction = existing == null
      ? DebtDirection.iOwe
      : DebtDirection.values[existing.direction];
  DateTime? dueDate = existing?.dueDate;
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
            Text(isEdit ? Tr.of(ctx).editDebt : Tr.of(ctx).newDebt,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TabsPill(
              tabs: [Tr.of(ctx).iOwe, Tr.of(ctx).owedToMe],
              index: direction.index,
              onChanged: (i) =>
                  setSt(() => direction = DebtDirection.values[i]),
              limeActive: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration:
                  InputDecoration(labelText: Tr.of(ctx).toFromWhom),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: Tr.of(ctx).amount),
            ),
            const SizedBox(height: 12),
            Pressable(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate:
                      dueDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365)),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setSt(() => dueDate = picked);
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
                    Expanded(
                      child: Text(dueDate == null
                          ? Tr.of(ctx).dueDateLabel
                          : DateFormat('d MMMM y',
                                  Localizations.localeOf(ctx).languageCode)
                              .format(dueDate!)),
                    ),
                    if (dueDate != null)
                      Pressable(
                        onTap: () => setSt(() => dueDate = null),
                        child: Icon(LucideIcons.x,
                            size: 16, color: ctx.faintText),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ScaledElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty || amount <= 0) return;
                final repo = ref.read(debtRepositoryProvider);
                if (isEdit) {
                  await repo.update(
                    id: existing.id,
                    counterparty: nameCtrl.text.trim(),
                    amount: amount,
                    direction: direction,
                    dueDate: dueDate,
                    clearDueDate: dueDate == null,
                  );
                } else {
                  final currency =
                      ref.read(settingsControllerProvider).baseCurrency;
                  await repo.add(
                    counterparty: nameCtrl.text.trim(),
                    amount: amount,
                    currency: currency,
                    direction: direction,
                    dueDate: dueDate,
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
                      title: Text(Tr.of(dctx).deleteDebtTitle),
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
                  await ref.read(debtRepositoryProvider).delete(existing.id);
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });
  final String label;
  final String value;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: context.mutedText,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 11, color: context.faintText)),
        ],
      ),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  const _DebtCard({required this.debt});
  final db.Debt debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isIOwe = debt.direction == DebtDirection.iOwe.index;
    final progress = debt.amount > 0 ? (debt.paidAmount / debt.amount).clamp(0, 1) : 0;
    final remaining = debt.amount - debt.paidAmount;

    String dueLabel;
    Color dueColor = context.faintText;
    if (debt.dueDate != null) {
      final days = debt.dueDate!.difference(DateTime.now()).inDays;
      dueLabel =
          '${tr.duePrefix}${DateFormat('d MMM y', locale).format(debt.dueDate!)}';
      if (days <= 14 && days >= 0) {
        dueLabel += ' · $days ${tr.dayShort}';
        dueColor = AppColors.danger;
      } else if (days < 0) {
        dueLabel += ' · ${tr.overdue}';
        dueColor = AppColors.danger;
      }
    } else {
      dueLabel = tr.withoutDueDate;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () => _openDebtActions(context, ref),
        child: SoftCard(
          padding: const EdgeInsets.all(18),
          radius: 22,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _avatarColor(debt.counterparty),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      debt.counterparty.isNotEmpty
                          ? debt.counterparty[0].toUpperCase()
                          : '·',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.counterparty,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.primaryText),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 11, color: context.faintText),
                            children: [
                              TextSpan(
                                text: dueLabel,
                                style: TextStyle(color: dueColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    (isIOwe ? '−' : '+') +
                        formatMoney(remaining, debt.currency),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isIOwe
                          ? AppColors.danger
                          : AppColors.limeAccent,
                      letterSpacing: -0.5,
                    ),
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
                      color:
                          isIOwe ? AppColors.danger : AppColors.lime,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.paidOfTemplate
                        .replaceFirst(
                            '{p}', formatMoney(debt.paidAmount, debt.currency))
                        .replaceFirst(
                            '{t}', formatMoney(debt.amount, debt.currency)),
                    style: TextStyle(
                        fontSize: 11, color: context.faintText),
                  ),
                  Text('${(progress * 100).round()}%',
                      style: TextStyle(
                          fontSize: 11, color: context.faintText)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _avatarColor(String name) {
    const palette = [
      Color(0xFF5F27CD),
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFB84E),
      Color(0xFF7A9E1F),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  Future<void> _openDebtActions(BuildContext context, WidgetRef ref) async {
    final tr = Tr.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: SizedBox(
                  width: 36,
                  child: Divider(thickness: 4, color: ctx.handleBar),
                ),
              ),
              const SizedBox(height: 12),
              Text(debt.counterparty,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ctx.primaryText)),
              const SizedBox(height: 16),
              _actionTile(ctx, LucideIcons.plus, tr.repayment, () {
                Navigator.pop(ctx);
                _openPay(context, ref);
              }),
              _actionTile(ctx, LucideIcons.pencil, tr.edit, () {
                Navigator.pop(ctx);
                _openDebtEditor(context, ref, existing: debt);
              }),
              _actionTile(
                ctx,
                LucideIcons.trash2,
                tr.delete,
                () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dctx) => AlertDialog(
                      title: Text(Tr.of(dctx).deleteDebtTitle),
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
                  await ref.read(debtRepositoryProvider).delete(debt.id);
                },
                danger: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFE53E3E) : context.primaryText;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _openPay(BuildContext context, WidgetRef ref) async {
    final tr = Tr.of(context);
    final ctrl = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.repayment),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: tr.amount),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr.cancel)),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(ctrl.text) ?? 0),
            child: Text(tr.add),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      await ref.read(debtRepositoryProvider).addPayment(debt.id, result);
    }
  }
}
