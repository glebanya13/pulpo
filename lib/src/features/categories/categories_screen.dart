import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final catsAsync = ref.watch(categoriesProvider);
    final txsAsync = ref.watch(allTransactionsProvider);

    void retryLoad() {
      ref.invalidate(categoriesProvider);
      ref.invalidate(allTransactionsProvider);
    }

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
              first: tr.categories,
              onBack: () => context.pop(),
              action: RoundIconButton(
                icon: LucideIcons.plus,
                onTap: () => _openAdd(context),
              ),
            ),
        headerGap: 16,
        children: [
            TabsPill(
              tabs: [tr.expense, tr.income],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 16),
            AsyncValuesGate(
              values: [catsAsync, txsAsync],
              onRetry: retryLoad,
              child: Builder(
                builder: (context) {
                  final loadedCats = catsAsync.requireValue;
                  final txs = txsAsync.requireValue;
                  final wantedType = _tab == 0
                      ? CategoryType.expense.index
                      : CategoryType.income.index;
                  final visible = loadedCats
                      .where((c) =>
                          c.type == wantedType ||
                          c.type == CategoryType.both.index)
                      .toList();
                  final roots =
                      visible.where((c) => c.parentId == null).toList();
                  final byParent =
                      groupBy<db.Category, int?>(visible, (c) => c.parentId);

                  final counts = <int, int>{};
                  for (final t in txs) {
                    if (t.categoryId != null) {
                      counts.update(t.categoryId!, (v) => v + 1,
                          ifAbsent: () => 1);
                    }
                  }

                  return SoftCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < roots.length; i++) ...[
                          _CatRow(
                            category: roots[i],
                            count: counts[roots[i].id] ?? 0,
                            onTap: () => _openCategoryEditor(context, ref,
                                existing: roots[i]),
                          ),
                          for (final child in byParent[roots[i].id] ?? const [])
                            _CatRow(
                              category: child,
                              count: counts[child.id] ?? 0,
                              indent: true,
                              onTap: () => _openCategoryEditor(context, ref,
                                  existing: child),
                            ),
                          if (i != roots.length - 1)
                            const Divider(height: 1, color: AppColors.divider),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Future<void> _openAdd(BuildContext context) {
    final defaultType = _tab == 0 ? CategoryType.expense : CategoryType.income;
    return _openCategoryEditor(context, ref,
        existing: null, defaultType: defaultType);
  }
}

const _palette = categoryPalette;

const _iconKeys = [
  'utensils', 'car', 'home', 'heart-pulse', 'clapperboard', 'shirt',
  'wifi', 'graduation-cap', 'gift', 'sparkles', 'briefcase', 'laptop',
  'trending-up', 'wallet', 'credit-card', 'coins', 'piggy-bank',
  'target', 'plane', 'shopping-bag', 'circle',
];

Future<void> _openCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  required db.Category? existing,
  CategoryType defaultType = CategoryType.expense,
}) async {
  final nameCtrl = TextEditingController(
      text: existing == null ? '' : Tr.of(context).categoryName(existing.name));
  var color = existing?.color ?? 0xFF8BD44A;
  var icon = existing?.icon ?? 'circle';
  final isEdit = existing != null;

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
            Center(
              child: SizedBox(
                width: 36,
                child: Divider(thickness: 4, color: context.handleBar),
              ),
            ),
            const SizedBox(height: 12),
            Text(
                isEdit ? Tr.of(ctx).editCategory : Tr.of(ctx).newCategory,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: Tr.of(ctx).titleLabel),
            ),
            const SizedBox(height: 16),
            Text(Tr.of(ctx).colorLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ctx.mutedText)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _palette
                  .map((c) => Pressable(
                        onTap: () => setSt(() => color = c),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: color == c
                                ? Border.all(
                                    color: ctx.isDark
                                        ? Colors.white
                                        : AppColors.ink,
                                    width: 2)
                                : null,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(Tr.of(ctx).iconLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ctx.mutedText)),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final key in _iconKeys)
                  Pressable(
                    onTap: () => setSt(() => icon = key),
                    child: Container(
                      decoration: BoxDecoration(
                        color: icon == key
                            ? AppColors.lime.withValues(alpha: 0.3)
                            : ctx.scaffoldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: icon == key
                            ? Border.all(color: AppColors.lime, width: 2)
                            : null,
                      ),
                      child: Icon(lucideByKey(key),
                          color: ctx.primaryText),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ScaledElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final repo = ref.read(categoryRepositoryProvider);
                if (isEdit) {
                  await repo.update(
                    id: existing.id,
                    name: nameCtrl.text.trim(),
                    icon: icon,
                    color: color,
                  );
                } else {
                  await repo.add(
                    name: nameCtrl.text.trim(),
                    type: defaultType,
                    icon: icon,
                    color: color,
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
                      title: Text(Tr.of(dctx).deleteCategoryTitle),
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
                      .read(categoryRepositoryProvider)
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

class _CatRow extends StatelessWidget {
  const _CatRow({
    required this.category,
    required this.count,
    required this.onTap,
    this.indent = false,
  });
  final db.Category category;
  final int count;
  final bool indent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
      padding: EdgeInsets.only(left: indent ? 30 : 16, right: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.divider)),
        ),
        child: Row(
          children: [
            ColorWellIcon(
              color: Color(category.color),
              icon: lucideByKey(category.icon),
              size: indent ? 30 : 36,
              iconSize: indent ? 14 : 16,
              radius: indent ? 10 : 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                Tr.of(context).categoryName(category.name),
                style: TextStyle(
                    fontSize: indent ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: category.isHidden
                        ? context.faintText
                        : context.primaryText),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 12,
                  color: context.faintText,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight,
                size: 14, color: context.faintText),
          ],
        ),
      ),
      ),
    );
  }
}
