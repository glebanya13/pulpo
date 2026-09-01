import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/currencies.dart';
import '../../core/l10n/tr.dart';
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
import 'calendar_date_picker_sheet.dart';

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

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final picked = await showCalendarDatePicker(
      context,
      initial: _month,
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

        return Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  onFilterTypeChanged: (t) => setState(() => _filterType = t),
                  onAccountChanged: (id) => setState(() => _accountId = id),
                  onCategoryChanged: (id) => setState(() => _categoryId = id),
                ),
              ],
              const SizedBox(height: 6),
              if (_viewIndex == 0)
                _DailyMonthList(
                  month: _month,
                  txs: monthTxs,
                  currency: currency,
                  hasFilters: _hasActiveFilters,
                  monthHasTxs: monthTxsUnfiltered.isNotEmpty,
                  onClearFilters: _clearFilters,
                  onTapDay: (day) => _openDaySheet(context, day, monthTxs),
                  onTapTx: (tx) => context.push('/tx/${tx.id}'),
                  onDeleteTx: _deleteWithUndo,
                )
              else
                _MonthTable(
                  month: _month,
                  leading: leading,
                  daysInMonth: daysInMonth,
                  byDay: byDay,
                  currency: currency,
                  onTapDay: (day) => _openDaySheet(context, day, monthTxs),
                ),
            ],
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
    final dayTxs = monthTxs.where((t) {
      return t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day;
    }).toList();

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DaySheet(day: day, txs: dayTxs),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.onShift,
    required this.onTitleTap,
    required this.calendarView,
    required this.onToggleCalendar,
  });
  final DateTime month;
  final ValueChanged<int> onShift;
  final VoidCallback onTitleTap;
  final bool calendarView;
  final VoidCallback onToggleCalendar;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final title = DateFormat('LLL y', locale).format(month);
    final titleCapitalized =
        title.isEmpty ? title : title[0].toUpperCase() + title.substring(1);
    return Row(
      children: [
        _NavBtn(icon: LucideIcons.chevronLeft, onTap: () => onShift(-1)),
        Expanded(
          child: Center(
            child: Pressable(
              onTap: onTitleTap,
              child: Text(
                titleCapitalized,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
            ),
          ),
        ),
        _NavBtn(icon: LucideIcons.chevronRight, onTap: () => onShift(1)),
        const SizedBox(width: 4),
        Pressable(
          onTap: onToggleCalendar,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: calendarView
                  ? AppColors.lime.withValues(alpha: 0.2)
                  : context.scaffoldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.calendarDays,
              size: 15,
              color: calendarView
                  ? AppColors.limeAccent
                  : context.mutedText,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthTotals extends StatelessWidget {
  const _MonthTotals({
    required this.income,
    required this.expense,
    required this.net,
    required this.currency,
  });
  final double income;
  final double expense;
  final double net;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Mini(
              label: tr.income,
              value: formatMoney(income, currency),
              color: AppColors.limeAccent),
          Container(width: 1, height: 28, color: context.divider),
          _Mini(
              label: tr.expense,
              value: formatMoney(expense, currency),
              color: AppColors.danger),
          Container(width: 1, height: 28, color: context.divider),
          _Mini(
              label: tr.monthNet,
              value: formatMoney(net, currency),
              color: context.primaryText),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: context.mutedText),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: context.primaryText),
      ),
    );
  }
}

class _DailyMonthList extends StatelessWidget {
  const _DailyMonthList({
    required this.month,
    required this.txs,
    required this.currency,
    required this.hasFilters,
    required this.monthHasTxs,
    required this.onClearFilters,
    required this.onTapDay,
    required this.onTapTx,
    required this.onDeleteTx,
  });

  final DateTime month;
  final List<db.Transaction> txs;
  final String currency;
  final bool hasFilters;
  final bool monthHasTxs;
  final VoidCallback onClearFilters;
  final ValueChanged<DateTime> onTapDay;
  final ValueChanged<db.Transaction> onTapTx;
  final ValueChanged<db.Transaction> onDeleteTx;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).toString();
    final grouped = groupBy<db.Transaction, DateTime>(
      txs,
      (t) => DateTime(t.date.year, t.date.month, t.date.day),
    );
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (days.isEmpty) {
      if (hasFilters && monthHasTxs) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(
                tr.emptyFilterResults,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Pressable(
                onTap: onClearFilters,
                child: Text(
                  tr.clearFilters,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.limeAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Text(
          tr.noTxThisDay,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.mutedText, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final day in days) ...[
          Pressable(
            onTap: () => onTapDay(day),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.primaryText,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.scaffoldBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      DateFormat.E(locale).format(day),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.mutedText,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _DayTotalsRow(dayTxs: grouped[day]!, currency: currency),
                ],
              ),
            ),
          ),
          for (final tx in grouped[day]!)
            Dismissible(
              key: ValueKey(tx.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 20),
              ),
              onDismissed: (_) => onDeleteTx(tx),
              child: Pressable(
                onTap: () => onTapTx(tx),
                child: TransactionTile(tx: tx, embedded: true),
              ),
            ),
        ],
      ],
    );
  }
}

class _DayTotalsRow extends StatelessWidget {
  const _DayTotalsRow({required this.dayTxs, required this.currency});

  final List<db.Transaction> dayTxs;
  final String currency;

  @override
  Widget build(BuildContext context) {
    var income = 0.0;
    var expense = 0.0;
    for (final t in dayTxs) {
      final type = TxType.values[t.type];
      if (type == TxType.income) {
        income += t.amount;
      } else if (type == TxType.expense) {
        expense += t.amount;
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (income > 0)
          Text(
            formatMoney(income, currency),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.limeAccent,
            ),
          ),
        if (income > 0 && expense > 0) const SizedBox(width: 8),
        if (expense > 0)
          Text(
            formatMoney(expense, currency),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
      ],
    );
  }
}

class _MonthTable extends StatelessWidget {
  const _MonthTable({
    required this.month,
    required this.leading,
    required this.daysInMonth,
    required this.byDay,
    required this.currency,
    required this.onTapDay,
  });

  final DateTime month;
  final int leading;
  final int daysInMonth;
  final Map<int, ({double income, double expense})> byDay;
  final String currency;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final labels = Tr.of(context).weekdayShort;
    final prevMonthLast = DateTime(month.year, month.month, 0).day;
    final today = DateTime.now();
    // Always 6 weeks so month switches don't change calendar height.
    const rowCount = 6;

    _DayCell cellAt(int i) {
      final dayIndex = i - leading + 1;
      final inMonth = dayIndex >= 1 && dayIndex <= daysInMonth;

      final int displayDay;
      final DateTime cellDate;
      if (dayIndex < 1) {
        displayDay = prevMonthLast + dayIndex;
        cellDate = DateTime(month.year, month.month - 1, displayDay);
      } else if (dayIndex > daysInMonth) {
        displayDay = dayIndex - daysInMonth;
        cellDate = DateTime(month.year, month.month + 1, displayDay);
      } else {
        displayDay = dayIndex;
        cellDate = DateTime(month.year, month.month, dayIndex);
      }

      final isToday = inMonth &&
          today.year == cellDate.year &&
          today.month == cellDate.month &&
          today.day == cellDate.day;
      final sums = inMonth ? byDay[displayDay] : null;

      return _DayCell(
        day: displayDay,
        inMonth: inMonth,
        isToday: isToday,
        income: sums?.income ?? 0,
        expense: sums?.expense ?? 0,
        currency: currency,
        onTap: inMonth ? () => onTapDay(cellDate) : null,
      );
    }

    return Table(
      defaultColumnWidth: const FlexColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          children: [
            for (final l in labels)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Center(
                  child: Text(
                    l,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.faintText,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var row = 0; row < rowCount; row++)
          TableRow(
            children: [
              for (var col = 0; col < 7; col++) cellAt(row * 7 + col),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.income,
    required this.expense,
    required this.currency,
    required this.onTap,
  });

  final int day;
  final bool inMonth;
  final bool isToday;
  final double income;
  final double expense;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final numberColor = !inMonth
        ? context.faintText
        : (isToday ? AppColors.ink : context.primaryText);
    final showIncome = inMonth && income > 0;
    final showExpense = inMonth && expense > 0;
    final both = showIncome && showExpense;

    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.lime.withValues(alpha: 0.45)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$day',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: numberColor,
                  height: 1,
                ),
              ),
            ),
            // Fixed slot for up to 2 pills — keeps every row the same height.
            SizedBox(
              height: 28,
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIncome)
                      _Pill(
                        text: _shortMoney(income, currency),
                        color: AppColors.limeAccent,
                        compact: both,
                      ),
                    if (both) const SizedBox(height: 2),
                    if (showExpense)
                      _Pill(
                        text: _shortMoney(expense, currency),
                        color: AppColors.danger,
                        compact: both,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    this.compact = false,
  });
  final String text;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 4,
        vertical: compact ? 0.5 : 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day, required this.txs});
  final DateTime day;
  final List<db.Transaction> txs;

  void _openAdd(BuildContext context) {
    final router = GoRouter.of(context);
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    Navigator.of(context).pop();
    router.push('/add?date=$y-$m-$d');
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).toString();
    final title = DateFormat.yMMMMd(locale).format(day);
    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: context.handleBar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.primaryText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (txs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  tr.noTxThisDay,
                  style: TextStyle(color: context.mutedText),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: txs.length,
                itemBuilder: (ctx, i) {
                  final t = txs[i];
                  return Pressable(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/tx/${t.id}');
                    },
                    child: TransactionTile(tx: t),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          Pressable(
            onTap: () => _openAdd(context),
            scale: 0.97,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.plus, size: 22, color: AppColors.ink),
                  const SizedBox(width: 8),
                  Text(
                    tr.newTransaction,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Компактный формат суммы для пилюль в календаре: €752, €1,2K, €12K, €1M.
String _shortMoney(double value, String currency) {
  final symbol = _shortSymbol(currency);
  final abs = value.abs();
  String num;
  if (abs >= 1000000) {
    num = '${_trimZero((abs / 1000000).toStringAsFixed(1))}M';
  } else if (abs >= 10000) {
    num = '${(abs / 1000).round()}K';
  } else if (abs >= 1000) {
    num = '${_trimZero((abs / 1000).toStringAsFixed(1))}K';
  } else {
    num = abs.toStringAsFixed(0);
  }
  // Испанский формат — запятая как десятичный разделитель.
  num = num.replaceAll('.', ',');
  return '$symbol$num';
}

String _trimZero(String s) {
  if (s.endsWith('0')) {
    final dot = s.indexOf('.');
    if (dot != -1) return s.substring(0, dot);
  }
  return s;
}

String _shortSymbol(String code) {
  switch (code.toUpperCase()) {
    case 'XAF':
      return '';
    case 'DOP':
    case 'UYU':
      return r'$';
    default:
      return symbolForCode(code);
  }
}
