import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/transaction_tile.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../widgets/transaction_filters.dart';
import '../../widgets/pressable.dart';
import '../../widgets/simple_picker_sheet.dart';
import 'calendar_date_picker_sheet.dart';

part 'monthly_calendar_chrome.dart';
part 'monthly_calendar_views.dart';
part 'monthly_calendar_day_sheet.dart';

/// Календарь-обзор транзакций за месяц.
/// Ячейка дня: число + до двух пилюль (расход красная, доход зелёная).
/// Тап по дню — bottom sheet со списком транзакций этого дня.
class MonthlyCalendar extends ConsumerStatefulWidget {
  const MonthlyCalendar({super.key});

  @override
  ConsumerState<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends ConsumerState<MonthlyCalendar> {
  late DateTime _month;
  int _viewIndex = 0;
  String _query = '';
  TxType? _filterType;
  int? _accountId;
  int? _categoryId;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchCtrl.clear();
      _filterType = null;
      _accountId = null;
      _categoryId = null;
    });
  }

  bool get _hasActiveFilters =>
      _query.isNotEmpty ||
      _filterType != null ||
      _accountId != null ||
      _categoryId != null;

  Future<void> _deleteWithUndo(db.Transaction tx) async {
    HapticFeedback.mediumImpact();
    final tr = Tr.of(context);
    await ref.read(transactionRepositoryProvider).delete(tx.id);
    ref.invalidate(allTransactionsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr.txDeleted),
        behavior: SnackBarBehavior.floating,
        margin: AppSpacing.snackBarMargin(context),
        duration: const Duration(seconds: 5),
        // Flutter 3.37+: SnackBars with an action persist until tapped unless
        // persist is false (otherwise the undo toast never auto-dismisses).
        persist: false,
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

  Future<void> _duplicateTx(db.Transaction tx) async {
    if (tx.type == TxType.transfer.index) return;
    final currency = ref.read(settingsControllerProvider).baseCurrency;
    await ref.read(transactionRepositoryProvider).add(
      accountId: tx.accountId,
      categoryId: tx.categoryId,
      amount: tx.amount,
      currency: currency,
      type: TxType.values[tx.type],
      date: DateTime.now(),
      note: tx.note,
      counterparty: tx.counterparty,
    );
    ref.invalidate(allTransactionsProvider);
  }

  Future<void> _longPressTx(db.Transaction tx) async {
    final tr = Tr.of(context);
    await showSimpleSheet<void>(
      context: context,
      builder: (_) => SimplePickerSheet(
        maxHeightFraction: 0.38,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TxActionTile(
              icon: LucideIcons.pencil,
              label: tr.edit,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/tx/${tx.id}/edit');
              },
            ),
            if (tx.type != TxType.transfer.index)
              _TxActionTile(
                icon: LucideIcons.copy,
                label: tr.txDuplicate,
                onTap: () {
                  Navigator.of(context).pop();
                  _duplicateTx(tx);
                },
              ),
            _TxActionTile(
              icon: LucideIcons.trash2,
              label: tr.delete,
              danger: true,
              onTap: () {
                Navigator.of(context).pop();
                _deleteWithUndo(tx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final now = DateTime.now();
    // Viewing the current month → open with today selected; otherwise the
    // 1st of the viewed month (today isn't in it anyway).
    final initial = now.year == _month.year && now.month == _month.month
        ? DateTime(now.year, now.month, now.day)
        : _month;
    final picked = await showCalendarDatePicker(
      context,
      initial: initial,
    );
    if (picked == null || !mounted) return;
    setState(() => _month = DateTime(picked.year, picked.month, 1));
    final monthTxs = ref.read(allTransactionsProvider).valueOrNull;
    if (monthTxs == null) return;
    final monthStart = DateTime(picked.year, picked.month, 1);
    final monthEnd = DateTime(picked.year, picked.month + 1, 1);
    final filtered = monthTxs
        .where(
          (t) => !t.date.isBefore(monthStart) && t.date.isBefore(monthEnd),
        )
        .toList();
    if (!context.mounted) return;
    await _openDaySheet(context, picked, filtered);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsControllerProvider).baseCurrency;
    final tr = Tr.of(context);
    final monthStart = _month;
    final monthEnd = DateTime(_month.year, _month.month + 1, 1);
    // Use the full stream (already warm on dashboard) so month switches never
    // flash a loading spinner / collapse height.
    final allTxsAsync = ref.watch(allTransactionsProvider);
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];

    return AsyncValueView(
      value: allTxsAsync,
      onRetry: () => ref.invalidate(allTransactionsProvider),
      data: (allTxs) {
        final monthTxs = applyTransactionFilters(
          txs: allTxs
              .where(
                (t) =>
                    !t.date.isBefore(monthStart) && t.date.isBefore(monthEnd),
              )
              .toList(),
          query: _query,
          filterType: _filterType,
          accountId: _accountId,
          categoryId: _categoryId,
          categories: cats,
          tr: tr,
        );
        final monthTxsUnfiltered = allTxs
            .where(
              (t) => !t.date.isBefore(monthStart) && t.date.isBefore(monthEnd),
            )
            .toList();
        var income = 0.0;
        var expense = 0.0;
        final byDay = <int, ({double income, double expense})>{};
        for (final t in monthTxs) {
          final key = t.date.day;
          final prev = byDay[key] ?? (income: 0.0, expense: 0.0);
          final type = TxType.values[t.type];
          if (type == TxType.income) {
            income += t.amount;
            byDay[key] =
                (income: prev.income + t.amount, expense: prev.expense);
          } else if (type == TxType.expense) {
            expense += t.amount;
            byDay[key] =
                (income: prev.income, expense: prev.expense + t.amount);
          }
        }
        final net = income - expense;

        final firstWeekday = monthStart.weekday;
        final leading = firstWeekday - 1;
        final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  month: _month,
                  onShift: _shiftMonth,
                  onTitleTap: () => _openDatePicker(context),
                  calendarView: _viewIndex == 1,
                  onToggleCalendar: () => setState(
                    () => _viewIndex = _viewIndex == 0 ? 1 : 0,
                  ),
                ),
                const SizedBox(height: 6),
                _MonthTotals(
                  income: income,
                  expense: expense,
                  net: net,
                  currency: currency,
                ),
                if (_viewIndex == 0) ...[
                  const SizedBox(height: 6),
                  TransactionFiltersBar(
                    searchController: _searchCtrl,
                    query: _query,
                    filterType: _filterType,
                    accountId: _accountId,
                    categoryId: _categoryId,
                    accounts: accounts,
                    categories: cats,
                    onQueryChanged: (v) => setState(() => _query = v),
                    onFilterTypeChanged: (t) =>
                        setState(() => _filterType = t),
                    onAccountChanged: (id) =>
                        setState(() => _accountId = id),
                    onCategoryChanged: (id) =>
                        setState(() => _categoryId = id),
                  ),
                ],
                SizedBox(height: _viewIndex == 0 ? 6 : 10),
                if (_viewIndex == 0)
                  _DailyMonthList(
                    month: _month,
                    txs: monthTxs,
                    currency: currency,
                    hasFilters: _hasActiveFilters,
                    monthHasTxs: monthTxsUnfiltered.isNotEmpty,
                    onClearFilters: _clearFilters,
                    onTapDay: (day) =>
                        _openDaySheet(context, day, monthTxs),
                    onTapTx: (tx) => context.push('/tx/${tx.id}'),
                    onDeleteTx: _deleteWithUndo,
                    onLongPressTx: _longPressTx,
                  )
                else
                  _MonthTable(
                    month: _month,
                    leading: leading,
                    daysInMonth: daysInMonth,
                    byDay: byDay,
                    currency: currency,
                    onTapDay: (day) =>
                        _openDaySheet(context, day, monthTxs),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDaySheet(
    BuildContext context,
    DateTime day,
    List<db.Transaction> monthTxs,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DaySheet(
        day: day,
        onDeleteTx: _deleteWithUndo,
      ),
    );
  }
}
