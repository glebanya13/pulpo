import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/repositories/subscription_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final subs = ref.watch(subscriptionsProvider).valueOrNull ?? const [];
    final active = subs.where((s) => !s.isPaused).toList();
    final monthly = _monthlyTotal(active);
    final yearly = monthly * 12;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(
              first: tr.subscriptions,
              subtitle: tr.activeCount(active.length),
              onBack: () => context.pop(),
              action: RoundIconButton(
                icon: LucideIcons.plus,
                onTap: () => _openAdd(context, ref),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TotalCard(
                    label: tr.perMonth,
                    value: monthly,
                    accent: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TotalCard(
                    label: tr.perYear,
                    value: yearly,
                    accent: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (subs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: LucideIcons.tv,
                  title: tr.subsEmptyTitle,
                  description: tr.subsEmptyDesc,
                  background: AppColors.bgFood,
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  tr.nextPaymentLabel,
                  style: TextStyle(fontSize: 12, color: context.mutedText),
                ),
              ),
              if (active.isNotEmpty)
                _SubCard(sub: active.first, highlighted: true),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  tr.allSubscriptions,
                  style: TextStyle(fontSize: 12, color: context.mutedText),
                ),
              ),
              for (final s in subs) _SubCard(sub: s, highlighted: false),
            ],
          ],
        ),
      ),
    );
  }

  double _monthlyTotal(List<db.Subscription> subs) {
    var m = 0.0;
    for (final s in subs) {
      if (s.cycle == 'yearly') {
        m += s.amount / 12;
      } else {
        m += s.amount;
      }
    }
    return m;
  }

  Future<void> _openAdd(BuildContext context, WidgetRef ref) =>
      _openEditor(context, ref, existing: null);
}

Future<void> _openEditor(
  BuildContext context,
  WidgetRef ref, {
  required db.Subscription? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final amountCtrl = TextEditingController(
      text: existing == null ? '' : existing.amount.toString());
  var cycle = existing?.cycle ?? 'monthly';
  DateTime next =
      existing?.nextPayment ?? DateTime.now().add(const Duration(days: 30));
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
            Text(
                isEdit
                    ? Tr.of(ctx).editSubscription
                    : Tr.of(ctx).newSubscription,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration:
                  InputDecoration(labelText: Tr.of(ctx).serviceName),
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
              initialValue: cycle,
              decoration:
                  InputDecoration(labelText: Tr.of(ctx).periodicity),
              items: [
                DropdownMenuItem(
                    value: 'monthly', child: Text(Tr.of(ctx).monthlyLabel)),
                DropdownMenuItem(
                    value: 'yearly', child: Text(Tr.of(ctx).yearlyLabel)),
              ],
              onChanged: (v) => setSt(() => cycle = v ?? 'monthly'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: next,
                  firstDate: DateTime.now()
                      .subtract(const Duration(days: 365)),
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
                        '${Tr.of(ctx).nextPaymentPrefix}${DateFormat('d MMM y', Localizations.localeOf(ctx).languageCode).format(next)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ScaledElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty || amount <= 0) return;
                final repo = ref.read(subscriptionRepositoryProvider);
                if (isEdit) {
                  await repo.update(
                    id: existing.id,
                    name: nameCtrl.text.trim(),
                    amount: amount,
                    cycle: cycle,
                    nextPayment: next,
                  );
                } else {
                  await repo.add(
                    name: nameCtrl.text.trim(),
                    amount: amount,
                    currency: 'USD',
                    cycle: cycle,
                    nextPayment: next,
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
                      title: Text(Tr.of(dctx).deleteSubTitle),
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
                      .read(subscriptionRepositoryProvider)
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

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label;
  final double value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = context.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent
            ? accentColor.withValues(alpha: 0.1)
            : context.surface,
        border: accent
            ? Border.all(color: accentColor.withValues(alpha: 0.25))
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: context.mutedText, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent ? accentColor : context.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubCard extends ConsumerWidget {
  const _SubCard({required this.sub, required this.highlighted});
  final db.Subscription sub;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final daysUntil = sub.nextPayment.difference(DateTime.now()).inDays;

    final accentColor = context.accent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openEditor(context, ref, existing: sub),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? accentColor.withValues(alpha: 0.08)
            : context.surface,
        border: highlighted
            ? Border.all(color: accentColor.withValues(alpha: 0.25))
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Color(sub.logoColor),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              sub.logoLetter.isNotEmpty
                  ? sub.logoLetter
                  : sub.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: TextStyle(
                      color: context.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        color: context.mutedText, fontSize: 11),
                    children: [
                      TextSpan(
                          text:
                              '${sub.cycle == 'yearly' ? tr.yearlyLabel : tr.monthlyLabel} · '),
                      TextSpan(
                        text: highlighted && daysUntil <= 7
                            ? tr.inDays(daysUntil)
                            : DateFormat('d MMM', locale)
                                .format(sub.nextPayment),
                        style: highlighted
                            ? TextStyle(color: accentColor)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${sub.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: context.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
