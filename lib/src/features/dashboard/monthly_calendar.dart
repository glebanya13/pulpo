import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
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

    final byDay = <int, ({double income, double expense})>{};
    for (final t in monthTxs) {
      final key = t.date.day;
      final prev = byDay[key] ?? (income: 0.0, expense: 0.0);
      final type = TxType.values[t.type];
      if (type == TxType.income) {
        byDay[key] = (income: prev.income + t.amount, expense: prev.expense);
      } else if (type == TxType.expense) {
        byDay[key] = (income: prev.income, expense: prev.expense + t.amount);
      }
    }

    // Понедельник = 1 … воскресенье = 7 (DateTime.weekday).
    final firstWeekday = monthStart.weekday; // 1..7 (Mon..Sun)
    final leading = firstWeekday - 1; // сколько ячеек предыдущего месяца
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(month: _month, onShift: _shiftMonth),
          const SizedBox(height: 8),
          const _WeekdayRow(),
          const SizedBox(height: 4),
          _Grid(
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
    final title = DateFormat('MMMM y', 'es').format(month);
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
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: context.primaryText),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    final labels = Tr.of(context).weekdayShort;
    return Row(
      children: [
        for (final l in labels)
          Expanded(
            child: Center(
              child: Text(
                l,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: context.faintText,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
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
    final prevMonthLast = DateTime(month.year, month.month, 0).day;
    final today = DateTime.now();

    // Количество недель, реально нужных для показа месяца (5 или 6).
    final totalDays = leading + daysInMonth;
    final rowCount = (totalDays / 7).ceil();

    Widget buildCell(int i) {
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

      return Expanded(
        child: _DayCell(
          day: displayDay,
          inMonth: inMonth,
          isToday: isToday,
          income: sums?.income ?? 0,
          expense: sums?.expense ?? 0,
          currency: currency,
          onTap: inMonth ? () => onTapDay(cellDate) : null,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < rowCount; row++)
          SizedBox(
            height: 46,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++) buildCell(row * 7 + col),
              ],
            ),
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

    return Padding(
      padding: const EdgeInsets.all(1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.lime.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: numberColor,
                  height: 1.0,
                ),
              ),
              if (inMonth && expense > 0) ...[
                const SizedBox(height: 2),
                _Pill(
                  text: _shortMoney(expense, currency),
                  color: AppColors.danger,
                ),
              ],
              if (inMonth && income > 0) ...[
                const SizedBox(height: 2),
                _Pill(
                  text: _shortMoney(income, currency),
                  color: AppColors.limeAccent,
                ),
              ],
            ],
          ),
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
        overflow: TextOverflow.clip,
        softWrap: false,
        style: TextStyle(
          fontSize: 8.5,
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
    final title = DateFormat("d 'de' MMMM", 'es').format(day);
    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
    case 'EUR':
      return '€';
    case 'USD':
    case 'MXN':
    case 'ARS':
    case 'COP':
    case 'CLP':
    case 'UYU':
    case 'DOP':
    case 'CUP':
      return '\$';
    case 'PEN':
      return 'S/';
    case 'PYG':
      return '₲';
    case 'BOB':
      return 'Bs';
    case 'VES':
      return 'Bs.';
    case 'CRC':
      return '₡';
    case 'GTQ':
      return 'Q';
    case 'HNL':
      return 'L';
    case 'NIO':
      return 'C\$';
    case 'XAF':
      return '';
    default:
      return '';
  }
}
