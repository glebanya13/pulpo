import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _query = '';
  TxType? _filterType;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final txs = ref.watch(allTransactionsProvider).valueOrNull ?? const [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];

    final filtered = txs.where((t) {
      if (_filterType != null && TxType.values[t.type] != _filterType) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final cat = cats.firstWhereOrNull((c) => c.id == t.categoryId);
      return (t.note ?? '').toLowerCase().contains(q) ||
          (cat?.name ?? '').toLowerCase().contains(q);
    }).toList();

    final grouped = groupBy<db.Transaction, DateTime>(
      filtered,
      (t) => DateTime(t.date.year, t.date.month, t.date.day),
    );
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr.transactions,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: context.primaryText,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/accounts'),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.wallet,
                    size: 18,
                    color: context.isDark ? Colors.white : AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.search,
                  size: 18, color: context.faintText),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: tr.search,
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: false,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Chip(
                label: tr.all,
                active: _filterType == null,
                onTap: () => setState(() => _filterType = null),
              ),
              _Chip(
                label: tr.income,
                active: _filterType == TxType.income,
                onTap: () => setState(() => _filterType = TxType.income),
              ),
              _Chip(
                label: tr.expense,
                active: _filterType == TxType.expense,
                onTap: () => setState(() => _filterType = TxType.expense),
              ),
              _Chip(
                label: tr.transfer,
                active: _filterType == TxType.transfer,
                onTap: () => setState(() => _filterType = TxType.transfer),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(tr.emptyTransactionsList,
                  style: TextStyle(color: context.mutedText)),
            ),
          )
        else
          for (final day in sortedKeys) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _dayLabel(day, tr, context),
                style: TextStyle(
                  fontSize: 12,
                  color: context.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...grouped[day]!.map(
              (t) => Dismissible(
                key: ValueKey(t.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => ref
                    .read(transactionRepositoryProvider)
                    .delete(t.id),
                child: InkWell(
                  onTap: () => context.push('/tx/${t.id}'),
                  borderRadius: BorderRadius.circular(18),
                  child: TransactionTile(tx: t),
                ),
              ),
            ),
          ],
      ],
    );
  }

  String _dayLabel(DateTime d, Tr tr, BuildContext ctx) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return tr.today.toUpperCase();
    if (d == today.subtract(const Duration(days: 1))) {
      return tr.yesterday.toUpperCase();
    }
    final code = Localizations.localeOf(ctx).languageCode;
    return DateFormat('d MMMM', code).format(d).toUpperCase();
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? (context.isDark ? AppColors.ink3 : AppColors.ink)
                : context.surface,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : context.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}
