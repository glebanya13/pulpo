import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../widgets/common.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final all = ref.watch(allTransactionsProvider).valueOrNull ?? const [];
    final tx = all.where((t) => t.id == id).firstOrNull;
    if (tx == null) {
      return Scaffold(
        body: Center(child: Text(tr.txNotFound)),
      );
    }
    final category = ref.watch(categoryByIdProvider(tx.categoryId));
    final account = ref.watch(accountByIdProvider(tx.accountId));
    final type = TxType.values[tx.type];
    final isIncome = type == TxType.income;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RoundIconButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: () => context.pop(),
                ),
                Text(tr.transactionSingular,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.primaryText)),
                RoundIconButton(
                  icon: LucideIcons.pencil,
                  onTap: () => context.push('/tx/${tx.id}/edit'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                (isIncome ? '+' : '−') + formatMoney(tx.amount, tx.currency),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  color: isIncome ? context.accent : context.primaryText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: BudgetBadge(
                text: _typeLabel(type, tr),
                tone: isIncome ? BadgeTone.green : BadgeTone.red,
              ),
            ),
            const SizedBox(height: 24),
            _FormBlock(
              rows: [
                _row(
                  context,
                  icon: category != null
                      ? lucideByKey(category.icon)
                      : LucideIcons.tag,
                  bg: category != null
                      ? Color(category.color)
                      : context.scaffoldBg,
                  label: tr.category,
                  value: category != null
                      ? tr.categoryName(category.name)
                      : '—',
                ),
                _row(
                  context,
                  icon: LucideIcons.creditCard,
                  bg: context.scaffoldBg,
                  label: tr.account,
                  value: account?.name ?? '—',
                ),
                _row(
                  context,
                  icon: LucideIcons.calendar,
                  bg: context.scaffoldBg,
                  label: tr.date,
                  value: DateFormat('d MMMM y · HH:mm',
                          Localizations.localeOf(context).languageCode)
                      .format(tx.date),
                ),
                if (tx.counterparty != null)
                  _row(
                    context,
                    icon: LucideIcons.mapPin,
                    bg: context.scaffoldBg,
                    label: tr.txLocation,
                    value: tx.counterparty!,
                  ),
                _row(
                  context,
                  icon: LucideIcons.pencil,
                  bg: context.scaffoldBg,
                  label: tr.note,
                  value: tx.note?.isNotEmpty == true ? tx.note! : '—',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: tr.txDuplicate,
                    onTap: () async {
                      await ref.read(transactionRepositoryProvider).add(
                            accountId: tx.accountId,
                            categoryId: tx.categoryId,
                            amount: tx.amount,
                            currency: tx.currency,
                            type: type,
                            date: DateTime.now(),
                            note: tx.note,
                          );
                      if (context.mounted) context.pop();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: tr.delete,
                    danger: true,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(tr.deleteTxTitle),
                          content: Text(tr.deleteTxBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(tr.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFE53E3E),
                              ),
                              child: Text(tr.delete),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await ref
                          .read(transactionRepositoryProvider)
                          .delete(tx.id);
                      if (context.mounted) context.pop();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('ID: txn_${tx.id}',
                  style: TextStyle(
                      fontSize: 10, color: context.faintText)),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(TxType t, Tr tr) {
    switch (t) {
      case TxType.income:
        return tr.incomeLower;
      case TxType.expense:
        return tr.expenseLower;
      case TxType.transfer:
        return tr.transferLower;
    }
  }
}

Widget _row(
  BuildContext context, {
  required IconData icon,
  required Color bg,
  required String label,
  required String value,
}) {
  final iconOnScaffold = bg == context.scaffoldBg;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 14,
              color: iconOnScaffold ? context.primaryText : AppColors.ink),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(fontSize: 13, color: context.mutedText)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.primaryText),
          ),
        ),
      ],
    ),
  );
}

class _FormBlock extends StatelessWidget {
  const _FormBlock({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(height: 1, color: context.divider),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFFE4E1) : Colors.transparent,
          border: danger
              ? null
              : Border.all(color: context.divider, width: 1.5),
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: danger ? const Color(0xFFE53E3E) : context.primaryText,
          ),
        ),
      ),
    );
  }
}
