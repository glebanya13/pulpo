import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

/// Full transaction list for one account — opened from «Ver todo».
class AccountTransactionsScreen extends ConsumerWidget {
  const AccountTransactionsScreen({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final accountsAsync = ref.watch(accountsProvider);
    final txsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: StickyScrollPage(
        header: PageHeader(
          first: tr.recentTransactions,
          onBack: () => context.pop(),
        ),
        headerGap: 12,
        children: [
          AsyncValuesGate(
            values: [accountsAsync, txsAsync],
            onRetry: () {
              ref.invalidate(accountsProvider);
              ref.invalidate(allTransactionsProvider);
            },
            child: Builder(
              builder: (context) {
                final account = ref.watch(accountByIdProvider(accountId));
                final txs = [
                  for (final t in txsAsync.requireValue)
                    if (t.accountId == accountId) t,
                ]..sort((a, b) => b.date.compareTo(a.date));

                if (account == null) {
                  return Text(
                    tr.account,
                    style: const TextStyle(color: Colors.white54),
                  );
                }

                if (txs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        tr.emptyTransactionsList,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final t in txs) _AccountTxRow(tx: t),
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

class _AccountTxRow extends ConsumerWidget {
  const _AccountTxRow({required this.tx});

  final db.Transaction tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final cat = ref.watch(categoryByIdProvider(tx.categoryId));
    final type = TxType.values[tx.type];
    final isIncome = type == TxType.income;
    final hidden = ref.watch(
      settingsControllerProvider.select((s) => s.hideBalances),
    );
    final locale = Localizations.localeOf(context).languageCode;
    final title = tx.note?.isNotEmpty == true
        ? tx.note!
        : (cat != null ? tr.categoryName(cat.name) : tr.transactionSingular);

    return Pressable(
      onTap: () => context.push('/tx/${tx.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                cat != null ? lucideByKey(cat.icon) : LucideIcons.circle,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('d MMM yyyy', locale).format(tx.date),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              hidden
                  ? kMaskedMoney
                  : (isIncome ? '+' : '−') +
                      formatMoney(tx.amount, tx.currency),
              style: TextStyle(
                color: isIncome
                    ? AppColors.lime
                    : type == TxType.expense
                        ? AppColors.danger
                        : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
