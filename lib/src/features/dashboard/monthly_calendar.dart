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
import '../../widgets/transaction_tile.dart';

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsControllerProvider).baseCurrency;
    final monthStart = _month;
    final monthEnd = DateTime(_month.year, _month.month + 1, 1);
    final monthTxs = ref
            .watch(transactionsInRangeProvider(
                (start: monthStart, end: monthEnd)))
            .valueOrNull ??
        const <db.Transaction>[];

    var income = 0.0;
    var expense = 0.0;
    final byDay = <int, ({double income, double expense})>{};
    for (final t in monthTxs) {
      final key = t.date.day;
      final prev = byDay[key] ?? (income: 0.0, expense: 0.0);
      final type = TxType.values[t.type];
      if (type == TxType.income) {
        income += t.amount;
        byDay[key] = (income: prev.income + t.amount, expense: prev.expense);
      } else if (type == TxType.expense) {
        expense += t.amount;
        byDay[key] = (income: prev.income, expense: prev.expense + t.amount);
      }
    }
    final net = income - expense;

    // Понедельник = 1 … воскресенье = 7 (DateTime.weekday).
    final firstWeekday = monthStart.weekday; // 1..7 (Mon..Sun)
    final leading = firstWeekday - 1; // сколько ячеек предыдущего месяца
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
          _Header(month: _month, onShift: _shiftMonth),
          const SizedBox(height: 8),
          _MonthTotals(
            income: income,
            expense: expense,
            net: net,
            currency: currency,
          ),
          const SizedBox(height: 8),
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
  const _Header({required this.month, required this.onShift});
  final DateTime month;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final title = DateFormat('LLLL y', locale).format(month);
    final titleCapitalized =
        title.isEmpty ? title : title[0].toUpperCase() + title.substring(1);
    return Row(
      children: [
        _NavBtn(icon: LucideIcons.chevronLeft, onTap: () => onShift(-1)),
        Expanded(
          child: Center(
            child: Text(
              titleCapitalized,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.primaryText,
              ),
            ),
          ),
        ),
        _NavBtn(icon: LucideIcons.chevronRight, onTap: () => onShift(1)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: context.mutedText)),
            const SizedBox(height: 2),
            Text(
              value,
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
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: context.primaryText),
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
    final totalDays = leading + daysInMonth;
    final rowCount = (totalDays / 7).ceil();

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
    final showExpense = inMonth && expense > 0;
    final showIncome = inMonth && income > 0 && expense <= 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
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
            if (showExpense)
              _Pill(
                  text: _shortMoney(expense, currency),
                  color: AppColors.danger),
            if (showIncome)
              _Pill(
                  text: _shortMoney(income, currency),
                  color: AppColors.limeAccent),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
          fontSize: 9,
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
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: txs.length,
                itemBuilder: (ctx, i) {
                  final t = txs[i];
                  return InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/tx/${t.id}');
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: TransactionTile(tx: t),
                  );
                },
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
