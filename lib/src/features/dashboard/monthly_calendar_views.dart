part of 'monthly_calendar.dart';

class _CalendarChrome extends StatelessWidget {
  const _CalendarChrome({
    required this.month,
    required this.onShift,
    required this.onTitleTap,
    required this.calendarView,
    required this.onToggleCalendar,
    required this.income,
    required this.expense,
    required this.net,
    required this.currency,
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
    required this.showFilters,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.roundBottom,
    this.body,
  });

  final DateTime month;
  final ValueChanged<int> onShift;
  final VoidCallback onTitleTap;
  final bool calendarView;
  final VoidCallback onToggleCalendar;
  final double income;
  final double expense;
  final double net;
  final String currency;
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
  final bool showFilters;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final bool roundBottom;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final bodyWidget = body;
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(18),
          bottom: roundBottom ? const Radius.circular(18) : Radius.zero,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(6, 6, 6, roundBottom ? 6 : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              month: month,
              onShift: onShift,
              onTitleTap: onTitleTap,
              calendarView: calendarView,
              onToggleCalendar: onToggleCalendar,
            ),
            const SizedBox(height: 6),
            _MonthTotals(
              income: income,
              expense: expense,
              net: net,
              currency: currency,
            ),
            if (showFilters) ...[
              const SizedBox(height: 6),
              TransactionFiltersBar(
                searchController: searchController,
                query: query,
                filterType: filterType,
                accountId: accountId,
                categoryId: categoryId,
                accounts: accounts,
                categories: categories,
                onQueryChanged: onQueryChanged,
                onFilterTypeChanged: onFilterTypeChanged,
                onAccountChanged: onAccountChanged,
                onCategoryChanged: onCategoryChanged,
              ),
            ],
            SizedBox(height: showFilters ? 6 : 10),
            ...switch ((errorMessage, loading, bodyWidget)) {
              (final msg?, _, _) => [
                  ErrorView(message: msg, onRetry: onRetry),
                ],
              (_, true, _) => const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              (_, _, final b?) => [b],
              _ => const <Widget>[],
            },
          ],
        ),
      ),
    );
  }
}

class _DailyEmptyState extends StatelessWidget {
  const _DailyEmptyState({
    required this.hasFilters,
    required this.monthHasTxs,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final bool monthHasTxs;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.accent,
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
        style: TextStyle(
          color: context.mutedText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.day,
    required this.txs,
    required this.currency,
    required this.locale,
    required this.isLast,
    required this.onTapDay,
    required this.onTapTx,
    required this.onDeleteTx,
    this.onLongPressTx,
  });

  final DateTime day;
  final List<db.Transaction> txs;
  final String currency;
  final String locale;
  final bool isLast;
  final VoidCallback onTapDay;
  final ValueChanged<db.Transaction> onTapTx;
  final ValueChanged<db.Transaction> onDeleteTx;
  final ValueChanged<db.Transaction>? onLongPressTx;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Container(
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Pressable(
              onTap: onTapDay,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat.E(locale).format(day),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.mutedText,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _DayHeaderTotals(dayTxs: txs, currency: currency),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: [
                  for (var i = 0; i < txs.length; i++)
                    Dismissible(
                      key: ValueKey(txs[i].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: EdgeInsets.only(bottom: i < txs.length - 1 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onDismissed: (_) => onDeleteTx(txs[i]),
                      child: Pressable(
                        onTap: () => onTapTx(txs[i]),
                        onLongPress: onLongPressTx != null
                            ? () => onLongPressTx!(txs[i])
                            : null,
                        child: TransactionTile(
                          tx: txs[i],
                          embedded: true,
                          embeddedInDayBlock: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeaderTotals extends StatelessWidget {
  const _DayHeaderTotals({required this.dayTxs, required this.currency});

  final List<db.Transaction> dayTxs;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
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
    final net = income - expense;
    final netColor = net > 0
        ? context.accent
        : net < 0
            ? AppColors.danger
            : context.mutedText;
    final showBreakdown = income > 0 && expense > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showBreakdown)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatMoney(income, currency, showSign: true),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.accent,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatMoney(-expense, currency, showSign: true),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        if (showBreakdown) const SizedBox(height: 2),
        Text(
          formatMoney(net, currency, showSign: true),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: netColor,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          tr.monthNet,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: context.faintText,
            letterSpacing: 0.2,
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
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
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
                        text: _shortMoney(income),
                        color: context.accent,
                        compact: both,
                      ),
                    if (both) const SizedBox(height: 2),
                    if (showExpense)
                      _Pill(
                        text: _shortMoney(expense),
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
