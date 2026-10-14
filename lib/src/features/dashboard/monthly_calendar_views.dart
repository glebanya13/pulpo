part of 'monthly_calendar.dart';

class _CalendarChrome extends StatelessWidget {
  const _CalendarChrome({
    required this.month,
    required this.viewIndex,
    required this.onShift,
    required this.onTitleTap,
    required this.onViewChanged,
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
  final int viewIndex;
  final ValueChanged<int> onShift;
  final VoidCallback onTitleTap;
  final ValueChanged<int> onViewChanged;
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
    // Flat on scaffold — no nested surface “подфон” so content is wider.
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 4, 4, roundBottom ? 4 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            month: month,
            viewIndex: viewIndex,
            onShift: onShift,
            onTitleTap: onTitleTap,
          ),
          const SizedBox(height: 6),
          _ViewTabs(index: viewIndex, onChanged: onViewChanged),
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
          SizedBox(height: showFilters ? 6 : 8),
          ...switch ((errorMessage, loading, bodyWidget)) {
            (final msg?, _, _) => [
                ErrorView(message: msg, onRetry: onRetry),
              ],
            // Prefer real body over a spinner — month switches must not
            // tear down the calendar grid for a loading flash.
            (_, _, final b?) => [b],
            (_, true, _) => const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            _ => const <Widget>[],
          },
        ],
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
    var weekday = DateFormat.E(locale).format(day);
    if (weekday.isNotEmpty) {
      weekday = weekday[0].toUpperCase() + weekday.substring(1);
    }
    // Day net only when 2+ txs — a single income/expense would just
    // duplicate the amount already shown on the row.
    final multi = txs.length > 1;
    var income = 0.0;
    var expense = 0.0;
    if (multi) {
      for (final t in txs) {
        final type = TxType.values[t.type];
        if (type == TxType.income) {
          income += t.amount;
        } else if (type == TxType.expense) {
          expense += t.amount;
        }
      }
    }
    final net = income - expense;

    // One surface card per day — ops stay grouped so days don’t glue together.
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Pressable(
              onTap: onTapDay,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(
                  children: [
                    Text(
                      day.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.scaffoldBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        weekday,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.mutedText,
                          height: 1,
                        ),
                      ),
                    ),
                    if (multi) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (income > 0)
                                Text(
                                  formatMoney(
                                    income,
                                    currency,
                                    showSign: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.accent,
                                  ),
                                ),
                              if (income > 0 && expense > 0)
                                const SizedBox(width: 8),
                              if (expense > 0)
                                Text(
                                  formatMoney(
                                    -expense,
                                    currency,
                                    showSign: true,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger,
                                  ),
                                ),
                              if (income > 0 || expense > 0)
                                const SizedBox(width: 8),
                              Text(
                                formatMoney(net, currency, showSign: true),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.totalBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: context.divider),
            for (var i = 0; i < txs.length; i++)
              Dismissible(
                key: ValueKey(txs[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  color: AppColors.danger,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 16,
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
                    showDivider: i < txs.length - 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthTable extends StatelessWidget {
  const _MonthTable({
    required this.month,
    required this.leading,
    required this.daysInMonth,
    required this.byDay,
    required this.onTapDay,
  });

  final DateTime month;
  final int leading;
  final int daysInMonth;
  final Map<int, ({double income, double expense, int count})> byDay;
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
        weekday: cellDate.weekday,
        income: sums?.income ?? 0,
        expense: sums?.expense ?? 0,
        txCount: sums?.count ?? 0,
        onTap: inMonth ? () => onTapDay(cellDate) : null,
      );
    }

    return Table(
      border: TableBorder.symmetric(
        inside: BorderSide(color: context.divider, width: 0.5),
      ),
      defaultColumnWidth: const FlexColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, top: 2),
                child: Center(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      // Mon–Sun labels: weekend tinted with our palette.
                      color: i >= 5 ? context.accent : context.faintText,
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
    required this.weekday,
    required this.income,
    required this.expense,
    required this.txCount,
    required this.onTap,
  });

  final int day;
  final bool inMonth;
  final bool isToday;
  final int weekday;
  final double income;
  final double expense;
  final int txCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final weekend = weekday == DateTime.saturday || weekday == DateTime.sunday;
    final numberColor = !inMonth
        ? context.faintText
        : isToday
            ? AppColors.ink
            : weekend
                ? context.accent
                : context.primaryText;
    final net = income - expense;
    // 1 op → blue net only; 2+ → income / expense / blue.
    final multi = txCount > 1;
    final showIncome = inMonth && multi && income > 0;
    final showExpense = inMonth && multi && expense > 0;
    final showNet = inMonth && txCount > 0;

    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
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
            const SizedBox(height: 2),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: Column(
                children: [
                  if (showIncome)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _shortMoney(income),
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.accent,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  if (showExpense)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _shortMoney(expense),
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  if (showNet)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _shortMoney(net),
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.totalBlue,
                            height: 1.1,
                          ),
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

String _padDayMonth(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Monday-start weeks that overlap [month] (newest first).
List<({DateTime start, DateTime end})> _weeksOverlappingMonth(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  var cursor = first.subtract(Duration(days: first.weekday - DateTime.monday));
  final weeks = <({DateTime start, DateTime end})>[];
  while (!cursor.isAfter(last)) {
    final end = cursor.add(const Duration(days: 6));
    if (!end.isBefore(first) && !cursor.isAfter(last)) {
      weeks.add((start: cursor, end: end));
    }
    cursor = cursor.add(const Duration(days: 7));
  }
  return weeks.reversed.toList();
}

/// Year overview — tap a month to expand weekly income/expense (in-month only).
class _YearMonthsList extends StatefulWidget {
  const _YearMonthsList({
    required this.year,
    required this.byMonth,
    required this.yearTxs,
    required this.currency,
    required this.onTapWeek,
  });

  final int year;
  final Map<int, ({double income, double expense})> byMonth;
  final List<db.Transaction> yearTxs;
  final String currency;
  final ValueChanged<DateTime> onTapWeek;

  @override
  State<_YearMonthsList> createState() => _YearMonthsListState();
}

class _YearMonthsListState extends State<_YearMonthsList> {
  int? _expandedMonth;

  ({double income, double expense}) _sumsInMonthWeek({
    required DateTime month,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    // Only days that belong to [month] — cross-month weeks never double-count.
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    var income = 0.0;
    var expense = 0.0;
    for (final t in widget.yearTxs) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (d.isBefore(weekStart) || d.isAfter(weekEnd)) continue;
      if (d.isBefore(monthStart) || !d.isBefore(monthEnd)) continue;
      final type = TxType.values[t.type];
      if (type == TxType.income) {
        income += t.amount;
      } else if (type == TxType.expense) {
        expense += t.amount;
      }
    }
    return (income: income, expense: expense);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    // Newest month first; hide future months of the current year.
    final lastMonth = widget.year == now.year ? now.month : 12;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var m = lastMonth; m >= 1; m--) ...[
          if (m < lastMonth)
            Divider(height: 1, thickness: 1, color: context.divider),
          _YearMonthRow(
            month: DateTime(widget.year, m, 1),
            income: widget.byMonth[m]?.income ?? 0,
            expense: widget.byMonth[m]?.expense ?? 0,
            currency: widget.currency,
            locale: locale,
            netLabel: tr.monthNet,
            expanded: _expandedMonth == m,
            onTap: () => setState(() {
              _expandedMonth = _expandedMonth == m ? null : m;
            }),
          ),
          if (_expandedMonth == m)
            for (final week in _weeksOverlappingMonth(
              DateTime(widget.year, m, 1),
            ))
              _YearWeekRow(
                weekStart: week.start,
                weekEnd: week.end,
                sums: _sumsInMonthWeek(
                  month: DateTime(widget.year, m, 1),
                  weekStart: week.start,
                  weekEnd: week.end,
                ),
                currency: widget.currency,
                onTap: () =>
                    widget.onTapWeek(DateTime(widget.year, m, 1)),
              ),
        ],
      ],
    );
  }
}

class _YearMonthRow extends StatelessWidget {
  const _YearMonthRow({
    required this.month,
    required this.income,
    required this.expense,
    required this.currency,
    required this.locale,
    required this.netLabel,
    required this.expanded,
    required this.onTap,
  });

  final DateTime month;
  final double income;
  final double expense;
  final String currency;
  final String locale;
  final String netLabel;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final name = DateFormat('LLL', locale).format(month);
    final nameCap =
        name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}';
    final mm = month.month.toString().padLeft(2, '0');
    final range = '01/$mm ~ ${lastDay.toString().padLeft(2, '0')}/$mm';

    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nameCap,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.primaryText,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Icon(
                        expanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: context.faintText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    range,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.faintText,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatMoney(income, currency),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          formatMoney(expense, currency),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$netLabel ${formatMoney(net, currency)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.faintText,
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

class _YearWeekRow extends StatelessWidget {
  const _YearWeekRow({
    required this.weekStart,
    required this.weekEnd,
    required this.sums,
    required this.currency,
    required this.onTap,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final ({double income, double expense}) sums;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final range = '${_padDayMonth(weekStart)} ~ ${_padDayMonth(weekEnd)}';
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 2, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                range,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.mutedText,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                formatMoney(sums.income, currency),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: Text(
                formatMoney(sums.expense, currency),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
