import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/l10n/tr.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../data/db/app_database.dart' as db;
import '../data/db/enums.dart';
import 'app_bottom_sheet.dart';
import 'common.dart';
import 'pressable.dart';

List<db.Transaction> applyTransactionFilters({
  required List<db.Transaction> txs,
  required String query,
  TxType? filterType,
  int? accountId,
  int? categoryId,
  required List<db.Category> categories,
  required Tr tr,
}) {
  return txs.where((t) {
    if (filterType != null && TxType.values[t.type] != filterType) {
      return false;
    }
    if (accountId != null && t.accountId != accountId) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final cat = categories.firstWhereOrNull((c) => c.id == t.categoryId);
    return (t.note ?? '').toLowerCase().contains(q) ||
        (cat != null && tr.categoryName(cat.name).toLowerCase().contains(q));
  }).toList();
}

class TransactionFiltersBar extends StatefulWidget {
  const TransactionFiltersBar({
    super.key,
    required this.searchController,
    required this.query,
    required this.filterType,
    required this.accountId,
    required this.categoryId,
    required this.accounts,
    required this.categories,
    required this.onQueryChanged,
    required this.onFilterTypeChanged,
    required this.onAccountChanged,
    required this.onCategoryChanged,
  });

  final TextEditingController searchController;
  final String query;
  final TxType? filterType;
  final int? accountId;
  final int? categoryId;
  final List<db.Account> accounts;
  final List<db.Category> categories;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TxType?> onFilterTypeChanged;
  final ValueChanged<int?> onAccountChanged;
  final ValueChanged<int?> onCategoryChanged;

  @override
  State<TransactionFiltersBar> createState() => _TransactionFiltersBarState();
}

class _TransactionFiltersBarState extends State<TransactionFiltersBar> {
  bool _expanded = false;

  bool get _hasActiveFilters =>
      widget.filterType != null ||
      widget.accountId != null ||
      widget.categoryId != null;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              flex: 5,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.scaffoldBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 17, color: context.faintText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: widget.searchController,
                        decoration: InputDecoration(
                          hintText: tr.search,
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                          filled: false,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.primaryText,
                        ),
                        onChanged: widget.onQueryChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Pressable(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _expanded || _hasActiveFilters
                      ? AppColors.lime.withValues(alpha: 0.2)
                      : context.scaffoldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: _hasActiveFilters
                      ? Border.all(
                          color: AppColors.lime.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.slidersHorizontal,
                      size: 17,
                      color: _expanded || _hasActiveFilters
                          ? context.accent
                          : context.mutedText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr.filter,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _expanded || _hasActiveFilters
                            ? context.accent
                            : context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          TabsPill(
            tabs: [tr.all, tr.income, tr.expense, tr.transfer],
            index: widget.filterType == null
                ? 0
                : widget.filterType == TxType.income
                    ? 1
                    : widget.filterType == TxType.expense
                        ? 2
                        : 3,
            onChanged: (i) => widget.onFilterTypeChanged(switch (i) {
                  1 => TxType.income,
                  2 => TxType.expense,
                  3 => TxType.transfer,
                  _ => null,
                }),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FilterPickChip(
                  label: tr.filterAccount,
                  value: widget.accounts
                      .where((a) => a.id == widget.accountId)
                      .map((a) => a.name)
                      .firstOrNull,
                  onTap: () async {
                    final picked = await openFilterPickSheet<int?>(
                      context,
                      title: tr.filterAccount,
                      items: [
                        (null, tr.all),
                        for (final a in widget.accounts) (a.id, a.name),
                      ],
                      selected: widget.accountId,
                    );
                    if (picked.didPick) widget.onAccountChanged(picked.value);
                  },
                  onClear: widget.accountId == null
                      ? null
                      : () => widget.onAccountChanged(null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterPickChip(
                  label: tr.filterCategory,
                  value: widget.categories
                      .where((c) => c.id == widget.categoryId)
                      .map((c) => tr.categoryName(c.name))
                      .firstOrNull,
                  onTap: () async {
                    final picked = await openFilterPickSheet<int?>(
                      context,
                      title: tr.filterCategory,
                      items: [
                        (null, tr.all),
                        for (final c in widget.categories)
                          (c.id, tr.categoryName(c.name)),
                      ],
                      selected: widget.categoryId,
                    );
                    if (picked.didPick) widget.onCategoryChanged(picked.value);
                  },
                  onClear: widget.categoryId == null
                      ? null
                      : () => widget.onCategoryChanged(null),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class FilterPickChip extends StatelessWidget {
  const FilterPickChip({
    super.key,
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
        height: 34,
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
          color: context.scaffoldBg,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? context.primaryText : context.mutedText,
                ),
              ),
            ),
            if (selected && onClear != null)
              Pressable(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.x,
                    size: 13,
                    color: context.mutedText,
                  ),
                ),
              )
            else
              Icon(LucideIcons.chevronDown, size: 14, color: context.faintText),
          ],
        ),
      ),
    );
  }
}

class FilterPickResult<T> {
  const FilterPickResult.cancelled() : didPick = false, value = null;
  const FilterPickResult.ok(this.value) : didPick = true;
  final bool didPick;
  final T? value;
}

Future<FilterPickResult<T>> openFilterPickSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> items,
  required T selected,
}) async {
  final picked = await showAppBottomSheet<FilterPickResult<T>>(
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
                          Navigator.pop(ctx, FilterPickResult.ok(item.$1)),
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
                            ? Icon(
                                LucideIcons.check,
                                color: ctx.accent,
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
  return picked ?? FilterPickResult<T>.cancelled();
}
