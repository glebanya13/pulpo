import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/reset_scroll_when_obscured.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _query = '';
  TxType? _filterType;
  int? _accountId;
  int? _categoryId;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteWithUndo(db.Transaction tx) async {
    final tr = Tr.of(context);
    await ref.read(transactionRepositoryProvider).delete(tx.id);
    ref.invalidate(allTransactionsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr.txDeleted),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: tr.undo,
          onPressed: () async {
            await ref.read(transactionRepositoryProvider).restore(tx);
            ref.invalidate(allTransactionsProvider);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final txsAsync = ref.watch(allTransactionsProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final cats = catsAsync.valueOrNull ?? const [];
    final accounts = accountsAsync.valueOrNull ?? const [];

    void retryLoad() {
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(accountsProvider);
    }

    return ResetScrollWhenObscured(
      tabPath: '/transactions',
      builder: (context, scroll) {
        final pad = AppSpacing.tabPagePadding(context);
        return StickyScrollPage(
          useSafeArea: false,
          controller: scroll,
          padding: pad,
          headerGap: 16,
          header: ScreenTitlePill(
            title: tr.transactions,
            large: true,
            expand: true,
            trailing: const HeaderSupportActions(dense: true),
          ),
          children: [
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
                  controller: _searchCtrl,
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
        TabsPill(
          tabs: [tr.all, tr.income, tr.expense, tr.transfer],
          index: _filterType == null
              ? 0
              : _filterType == TxType.income
                  ? 1
                  : _filterType == TxType.expense
                      ? 2
                      : 3,
          onChanged: (i) => setState(() {
            _filterType = switch (i) {
              1 => TxType.income,
              2 => TxType.expense,
              3 => TxType.transfer,
              _ => null,
            };
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _FilterPick(
                label: tr.filterAccount,
                value: accounts
                    .where((a) => a.id == _accountId)
                    .map((a) => a.name)
                    .firstOrNull,
                onTap: () => _pickAccount(context, tr, accounts),
                onClear: _accountId == null
                    ? null
                    : () => setState(() => _accountId = null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterPick(
                label: tr.filterCategory,
                value: cats
                    .where((c) => c.id == _categoryId)
                    .map((c) => tr.categoryName(c.name))
                    .firstOrNull,
                onTap: () => _pickCategory(context, tr, cats),
                onClear: _categoryId == null
                    ? null
                    : () => setState(() => _categoryId = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AsyncValuesGate(
          values: [txsAsync, catsAsync, accountsAsync],
          onRetry: retryLoad,
          child: Builder(
            builder: (context) {
              final txs = txsAsync.requireValue;
              final filtered = txs.where((t) {
                if (_filterType != null &&
                    TxType.values[t.type] != _filterType) {
                  return false;
                }
                if (_accountId != null && t.accountId != _accountId) {
                  return false;
                }
                if (_categoryId != null && t.categoryId != _categoryId) {
                  return false;
                }
                if (_query.isEmpty) return true;
                final q = _query.toLowerCase();
                final cat =
                    cats.firstWhereOrNull((c) => c.id == t.categoryId);
                return (t.note ?? '').toLowerCase().contains(q) ||
                    (cat != null &&
                        tr.categoryName(cat.name).toLowerCase().contains(q));
              }).toList();

              final grouped = groupBy<db.Transaction, DateTime>(
                filtered,
                (t) => DateTime(t.date.year, t.date.month, t.date.day),
              );
              final sortedKeys = grouped.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: LucideIcons.receipt,
                  title: tr.emptyTransactionsList,
                  description: tr.emptyTransactions,
                  action: tr.newTransaction,
                  onAction: () => context.push('/add'),
                  background: AppColors.bgFood,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                        onDismissed: (_) => _deleteWithUndo(t),
                        child: Pressable(
                          onTap: () => context.push('/tx/${t.id}'),
                          child: TransactionTile(tx: t),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
          ],
        );
      },
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

  Future<void> _pickAccount(
    BuildContext context,
    Tr tr,
    List<db.Account> accounts,
  ) async {
    final picked = await _openPickSheet<int?>(
      context,
      title: tr.filterAccount,
      items: [
        (null, tr.all),
        for (final a in accounts) (a.id, a.name),
      ],
      selected: _accountId,
    );
    if (!picked.didPick) return;
    setState(() => _accountId = picked.value);
  }

  Future<void> _pickCategory(
    BuildContext context,
    Tr tr,
    List<db.Category> cats,
  ) async {
    final picked = await _openPickSheet<int?>(
      context,
      title: tr.filterCategory,
      items: [
        (null, tr.all),
        for (final c in cats) (c.id, tr.categoryName(c.name)),
      ],
      selected: _categoryId,
    );
    if (!picked.didPick) return;
    setState(() => _categoryId = picked.value);
  }
}

class _SheetPick<T> {
  const _SheetPick.cancelled() : didPick = false, value = null;
  const _SheetPick.ok(this.value) : didPick = true;
  final bool didPick;
  final T? value;
}

Future<_SheetPick<T>> _openPickSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> items,
  required T selected,
}) async {
  final picked = await showAppBottomSheet<_SheetPick<T>>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      final bottomInset = MediaQuery.viewPaddingOf(ctx).bottom;
      final maxH = MediaQuery.sizeOf(ctx).height * 0.72;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ctx.handleBar,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ctx.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: ctx.divider,
                  ),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final active = item.$1 == selected;
                    return Pressable(
                      onTap: () =>
                          Navigator.pop(ctx, _SheetPick.ok(item.$1)),
                      scale: 0.98,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.$2,
                          style: TextStyle(
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: ctx.primaryText,
                          ),
                        ),
                        trailing: active
                            ? const Icon(
                                LucideIcons.check,
                                color: AppColors.limeAccent,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return picked ?? _SheetPick<T>.cancelled();
}

class _FilterPick extends StatelessWidget {
  const _FilterPick({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected ? value! : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? context.primaryText : context.mutedText,
                ),
              ),
            ),
            if (selected && onClear != null)
              Pressable(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(LucideIcons.x,
                      size: 14, color: context.mutedText),
                ),
              )
            else
              Icon(LucideIcons.chevronDown,
                  size: 16, color: context.faintText),
          ],
        ),
      ),
    );
  }
}
