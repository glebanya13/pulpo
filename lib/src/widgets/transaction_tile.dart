import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/l10n/tr.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/color_well.dart';
import '../core/utils/lucide_icon_map.dart';
import '../core/utils/money_format.dart';
import '../data/db/app_database.dart' as db;
import '../data/db/enums.dart';
import '../data/repositories/providers.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({super.key, required this.tx});
  final db.Transaction tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(tx.categoryId));
    final type = TxType.values[tx.type];
    final isIncome = type == TxType.income;
    final amountStr = formatMoney(
      isIncome ? tx.amount : -tx.amount,
      tx.currency,
      showSign: true,
    );
    final icon = category != null ? lucideByKey(category.icon) : Icons.paid;
    final wellColor = category != null
        ? Color(category.color)
        : (isIncome ? const Color(0xFF8BD44A) : const Color(0xFFFF5C5C));

    final dateStr = _humanDate(tx.date, context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ColorWellIcon(color: wellColor, icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note?.isNotEmpty == true
                      ? tx.note!
                      : (category != null
                          ? Tr.of(context).categoryName(category.name)
                          : Tr.of(context).transactionSingular),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${category != null ? Tr.of(context).categoryName(category.name) : _typeLabel(type, context)} · $dateStr',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.faintText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountStr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isIncome
                  ? (context.isDark
                      ? AppColors.lime
                      : AppColors.limeAccent)
                  : type == TxType.expense
                      ? AppColors.danger
                      : context.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(TxType t, BuildContext ctx) {
    final tr = Tr.of(ctx);
    switch (t) {
      case TxType.income:
        return tr.income;
      case TxType.expense:
        return tr.expense;
      case TxType.transfer:
        return tr.transfer;
    }
  }

  static String _humanDate(DateTime dt, BuildContext ctx) {
    final tr = Tr.of(ctx);
    final locale = Localizations.localeOf(ctx).languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return tr.today;
    if (d == today.subtract(const Duration(days: 1))) return tr.yesterday;
    return DateFormat('d MMM', locale).format(dt);
  }
}
