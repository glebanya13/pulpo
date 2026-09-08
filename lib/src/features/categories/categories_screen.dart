import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/async_value_view.dart';
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
                            onTap: () => context.push(
                                '/categories/${roots[i].id}/edit'),
                          ),
                          for (final child in byParent[roots[i].id] ?? const [])
                            _CatRow(
                              category: child,
                              count: counts[child.id] ?? 0,
                              indent: true,
                              onTap: () => context.push(
                                  '/categories/${child.id}/edit'),
                            ),
                          if (i != roots.length - 1)
                            Divider(height: 1, color: context.divider),
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

  void _openAdd(BuildContext context) {
    final type = _tab == 0 ? 'expense' : 'income';
    context.push('/categories/new?type=$type');
  }
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
