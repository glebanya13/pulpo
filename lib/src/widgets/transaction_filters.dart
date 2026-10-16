import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/l10n/tr.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../data/db/app_database.dart' as db;
import '../data/db/enums.dart';
import 'simple_picker_sheet.dart';
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
  if (txs.isEmpty) return const [];
  final q = query.trim().toLowerCase();
  final catNames = q.isEmpty
      ? null
      : {
          for (final c in categories)
            c.id: tr.categoryName(c.name).toLowerCase(),
        };
  return [
    for (final t in txs)
      if ((filterType == null || TxType.values[t.type] == filterType) &&
          (accountId == null || t.accountId == accountId) &&
          (categoryId == null || t.categoryId == categoryId) &&
          (q.isEmpty ||
              (t.note ?? '').toLowerCase().contains(q) ||
              (t.categoryId != null &&
                  (catNames?[t.categoryId]?.contains(q) ?? false))))
        t,
  ];
}

class TransactionFiltersBar extends StatelessWidget {
  const TransactionFiltersBar({
    super.key,
    required this.searchController,
    required this.query,
    required this.filterType,
    required this.accountId,
    required this.categoryId,
    required this.accounts,
    required this.categories,
    required this.expanded,
    required this.onExpandedChanged,
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
  /// Owned by the parent — survives list empty/non-empty rebuilds so type
  /// tabs (All / Income / …) stay visible while switching filters.
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TxType?> onFilterTypeChanged;
  final ValueChanged<int?> onAccountChanged;
  final ValueChanged<int?> onCategoryChanged;

  bool get _hasActiveFilters =>
      filterType != null || accountId != null || categoryId != null;

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
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 15, color: context.faintText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: tr.search,
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          filled: false,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.primaryText,
                        ),
                        onChanged: onQueryChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Pressable(
              onTap: () => onExpandedChanged(!expanded),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: (expanded || _hasActiveFilters)
                      ? AppColors.lime.withValues(alpha: 0.2)
                      : context.surface,
                  borderRadius: BorderRadius.circular(10),
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
                      size: 15,
                      color: (expanded || _hasActiveFilters)
                          ? context.accent
                          : context.mutedText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tr.filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: (expanded || _hasActiveFilters)
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
        if (expanded) ...[
          const SizedBox(height: 8),
          TabsPill(
            tabs: [tr.all, tr.income, tr.expense, tr.transfer],
            index: filterType == null
                ? 0
                : filterType == TxType.income
                    ? 1
                    : filterType == TxType.expense
                        ? 2
                        : 3,
            onChanged: (i) => onFilterTypeChanged(switch (i) {
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
                  value: accounts
                      .where((a) => a.id == accountId)
                      .map((a) => a.name)
                      .firstOrNull,
                  onTap: () async {
                    final picked = await openFilterPickSheet<int?>(
                      context,
                      title: tr.filterAccount,
                      items: [
                        (null, tr.all),
                        for (final a in accounts) (a.id, a.name),
                      ],
                      selected: accountId,
                    );
                    if (picked.didPick) onAccountChanged(picked.value);
                  },
                  onClear: accountId == null
                      ? null
                      : () => onAccountChanged(null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterPickChip(
                  label: tr.filterCategory,
                  value: categories
                      .where((c) => c.id == categoryId)
                      .map((c) => tr.categoryName(c.name))
                      .firstOrNull,
                  onTap: () async {
                    final picked = await openFilterPickSheet<int?>(
                      context,
                      title: tr.filterCategory,
                      items: [
                        (null, tr.all),
                        for (final c in categories)
                          (c.id, tr.categoryName(c.name)),
                      ],
                      selected: categoryId,
                    );
                    if (picked.didPick) onCategoryChanged(picked.value);
                  },
                  onClear: categoryId == null
                      ? null
                      : () => onCategoryChanged(null),
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
  final picked = await showSimpleSheet<FilterPickResult<T>>(
    context: context,
    builder: (ctx) => SimplePickerSheet(
      title: title,
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
  );
  return picked ?? FilterPickResult<T>.cancelled();
}
