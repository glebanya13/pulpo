import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/pressable.dart';
import '../../widgets/reset_scroll_when_obscured.dart';
import 'stats_period.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final tabs = [tr.tabOverview, tr.tabCategories, tr.tabTrends, tr.tabFlows];
    final currency = ref.watch(settingsControllerProvider).baseCurrency;
    final range = ref.watch(statsPeriodProvider);
    final txs = ref
            .watch(transactionsInRangeProvider(
                (start: range.start, end: range.end)))
            .valueOrNull ??
        const [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final monthCount = monthsCovered(range.start, range.end);

    String periodLabel(StatsPeriodKind k) {
      final t = Tr.of(context);
      switch (k) {
        case StatsPeriodKind.thisMonth:
          return t.periodThisMonth;
        case StatsPeriodKind.lastMonth:
          return t.periodLastMonth;
        case StatsPeriodKind.months3:
          return t.period3m;
        case StatsPeriodKind.months6:
          return t.period6m;
        case StatsPeriodKind.thisYear:
          return t.periodThisYear;
        case StatsPeriodKind.lastYear:
          return t.periodLastYear;
        case StatsPeriodKind.custom:
          return t.periodCustom;
      }
    }

    final periodName = periodLabel(range.kind);

    return ResetScrollWhenObscured(
      tabPath: '/reports',
      builder: (context, scroll) => ListView(
      controller: scroll,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.viewPaddingOf(context).top + 8,
        20,
        140,
      ),
      children: [
        Text(
          tr.analytics,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: context.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr.analyticsSubtitle,
          style: TextStyle(fontSize: 14, color: context.mutedText),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final k in StatsPeriodKind.values)
                if (k != StatsPeriodKind.custom) ...[
                  Pressable(
                    onTap: () =>
                        ref.read(statsPeriodProvider.notifier).setKind(k),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: range.kind == k
                            ? AppColors.lime
                            : context.surface,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        periodLabel(k),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: range.kind == k
                              ? AppColors.ink
                              : context.primaryText,
                        ),
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final active = _tab == i;
              return Pressable(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? (context.isDark ? AppColors.ink3 : AppColors.ink)
                        : context.surface,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : context.mutedText,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        ..._buildTabContent(
          txs: txs,
          cats: cats,
          now: now,
          rangeStart: range.start,
          rangeEnd: range.end,
          monthCount: monthCount,
          currency: currency,
          periodName: periodName,
          periodKind: range.kind,
        ),
      ],
    ),
    );
  }

  List<Widget> _buildTabContent({
    required List<db.Transaction> txs,
    required List<db.Category> cats,
    required DateTime now,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required int monthCount,
    required String currency,
    required String periodName,
    required StatsPeriodKind periodKind,
  }) {
    switch (_tab) {
      case 1:
        return _categoriesView(txs, cats, currency, periodName);
      case 2:
        return _trendsView(
          txs,
          rangeStart,
          rangeEnd,
          monthCount,
          currency,
          periodName,
          periodKind,
        );
      case 3:
        return _flowsView(txs, cats, currency, periodName);
      default:
        return _overviewView(
            txs, cats, now, rangeStart, monthCount, currency, periodName);
    }
  }

  // ─────────────────────── Overview ───────────────────────
  List<Widget> _overviewView(
    List<db.Transaction> txs,
    List<db.Category> cats,
    DateTime now,
    DateTime rangeStart,
    int monthCount,
    String currency,
    String periodName,
  ) {
    final monthly = List<double>.filled(monthCount, 0);
    for (final t in txs) {
      if (TxType.values[t.type] != TxType.expense) continue;
      final monthIdx = (t.date.year - rangeStart.year) * 12 +
          (t.date.month - rangeStart.month);
      if (monthIdx >= 0 && monthIdx < monthCount) monthly[monthIdx] += t.amount;
    }
    final total6m = monthly.fold<double>(0, (a, b) => a + b);
    final maxMonthly = monthly.reduce(math.max);

    final byCat = <int, double>{};
    var monthTotal = 0.0;
    for (final t in txs) {
      if (TxType.values[t.type] != TxType.expense) continue;
      byCat.update(t.categoryId ?? -1, (v) => v + t.amount,
          ifAbsent: () => t.amount);
      monthTotal += t.amount;
    }
    final donutData = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      _ChartCard(
        title: Tr.of(context).expensesForPeriod(periodName),
        value: formatMoney(total6m, currency),
        child: total6m <= 0
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  Tr.of(context).empty,
                  style: TextStyle(color: context.mutedText, fontSize: 14),
                ),
              )
            : SizedBox(
                height: 150,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (v, meta) {
                            final month = DateTime(rangeStart.year,
                                rangeStart.month + v.toInt(), 1);
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat(
                                        'LLL',
                                        Localizations.localeOf(context)
                                            .languageCode)
                                    .format(month),
                                style: TextStyle(
                                  color: v.toInt() == monthCount - 1
                                      ? AppColors.limeAccent
                                      : context.faintText,
                                  fontSize: 11,
                                  fontWeight: v.toInt() == monthCount - 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    maxY: maxMonthly * 1.2 + 1,
                    barGroups: [
                      for (var i = 0; i < monthCount; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: monthly[i],
                              color: i == monthCount - 1
                                  ? AppColors.lime
                                  : const Color(0xFFECECEC),
                              width: 18,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title:
            '${Tr.of(context).byCategoriesMonthPrefix}$periodName',
        value: '',
        child: donutData.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(Tr.of(context).empty,
                        style:
                            TextStyle(color: context.mutedText, fontSize: 14)),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatMoney(monthTotal, currency),
                          style: TextStyle(
                            color: context.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(Tr.of(context).totalWord,
                            style: TextStyle(
                                color: context.faintText, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              )
            : SizedBox(
                height: 160,
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            for (var i = 0; i < donutData.length; i++)
                              PieChartSectionData(
                                value: donutData[i].value,
                                color: _palette[i % _palette.length],
                                radius: 24,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatMoney(monthTotal, currency),
                            style: TextStyle(
                              color: context.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(Tr.of(context).totalWord,
                              style: TextStyle(
                                  color: context.faintText, fontSize: 12)),
                          const SizedBox(height: 10),
                          for (var i = 0;
                              i < donutData.length && i < 5;
                              i++) ...[
                            _legendItem(
                              color: _palette[i % _palette.length],
                              name: cats
                                      .where((c) => c.id == donutData[i].key)
                                      .map((c) =>
                                          Tr.of(context).categoryName(c.name))
                                      .firstOrNull ??
                                  Tr.of(context).other,
                              percent: monthTotal > 0
                                  ? (donutData[i].value / monthTotal * 100)
                                      .round()
                                  : 0,
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ];
  }

  // ─────────────────────── Categories ───────────────────────
  List<Widget> _categoriesView(
    List<db.Transaction> txs,
    List<db.Category> cats,
    String currency,
    String periodName,
  ) {
    final byCat = <int, double>{};
    for (final t in txs) {
      if (TxType.values[t.type] != TxType.expense) continue;
      byCat.update(t.categoryId ?? -1, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }
    final sorted = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.isEmpty ? 1.0 : sorted.first.value;

    if (sorted.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(Tr.of(context).noExpensesForPeriod(periodName),
                style: TextStyle(color: context.mutedText)),
          ),
        ),
      ];
    }

    return [
      _ChartCard(
        title:
            '${Tr.of(context).expensesByCategoriesMonthPrefix}$periodName',
        value: '',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in sorted) ...[
              _CategoryRow(
                category: cats.where((c) => c.id == e.key).firstOrNull,
                amount: e.value,
                fraction: e.value / maxVal,
                total: byCat.values.fold(0.0, (a, b) => a + b),
                currency: currency,
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    ];
  }

  // ─────────────────────── Trends ───────────────────────
  List<Widget> _trendsView(
    List<db.Transaction> txs,
    DateTime rangeStart,
    DateTime rangeEnd,
    int monthCount,
    String currency,
    String periodName,
    StatsPeriodKind periodKind,
  ) {
    // For "this month" render by day to avoid the "single point" look.
    if (periodKind == StatsPeriodKind.thisMonth) {
      final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      final lastInclusive = rangeEnd.subtract(const Duration(microseconds: 1));
      final dayCount = lastInclusive.difference(start).inDays + 1;
      final incomes = List<double>.filled(dayCount, 0);
      final expenses = List<double>.filled(dayCount, 0);

      for (final t in txs) {
        final txDay = DateTime(t.date.year, t.date.month, t.date.day);
        final dayIdx = txDay.difference(start).inDays;
        if (dayIdx < 0 || dayIdx >= dayCount) continue;
        final ty = TxType.values[t.type];
        if (ty == TxType.income) incomes[dayIdx] += t.amount;
        if (ty == TxType.expense) expenses[dayIdx] += t.amount;
      }

      final maxVal =
          math.max(incomes.reduce(math.max), expenses.reduce(math.max));

      final currentExpense = expenses[dayCount - 1];
      final prevExpense = dayCount > 1 ? expenses[dayCount - 2] : 0;
      final deltaPct = prevExpense > 0
          ? ((currentExpense - prevExpense) / prevExpense * 100).round()
          : 0;

      return [
        _ChartCard(
          title: Tr.of(context).incomeVsForPeriod(periodName),
          value: '',
          child: SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxVal * 1.2 + 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(
                    color: Color(0xFFECECEC),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= dayCount) return const SizedBox.shrink();
                        // Show first/middle/last to reduce clutter.
                        final show = i == 0 ||
                            i == dayCount - 1 ||
                            i == (dayCount ~/ 2);
                        if (!show) return const SizedBox.shrink();
                        final day = start.add(Duration(days: i));
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('d', Localizations.localeOf(context).languageCode)
                                .format(day),
                            style: TextStyle(
                              color: context.faintText,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < dayCount; i++)
                        FlSpot(i.toDouble(), incomes[i]),
                    ],
                    color: AppColors.limeAccent,
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.limeAccent,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.lime.withValues(alpha: 0.2),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < dayCount; i++)
                        FlSpot(i.toDouble(), expenses[i]),
                    ],
                    color: AppColors.danger,
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.danger,
                        strokeWidth: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.limeAccent),
                  const SizedBox(width: 6),
                  Text(
                    Tr.of(context).income,
                    style: TextStyle(
                      color: context.primaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Text(
                    Tr.of(context).expense,
                    style: TextStyle(
                      color: context.primaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _TrendStat(
                label: Tr.of(context).expenseToday,
                value: formatMoney(currentExpense, currency),
                accent: AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrendStat(
                label: Tr.of(context).vsYesterday,
                value: '${deltaPct >= 0 ? '+' : ''}$deltaPct%',
                accent: deltaPct > 0 ? AppColors.limeAccent : AppColors.danger,
              ),
            ),
          ],
        ),
      ];
    }

    // Default: month buckets.
    final incomes = List<double>.filled(monthCount, 0);
    final expenses = List<double>.filled(monthCount, 0);
    for (final t in txs) {
      final monthIdx = (t.date.year - rangeStart.year) * 12 +
          (t.date.month - rangeStart.month);
      if (monthIdx < 0 || monthIdx >= monthCount) continue;
      final ty = TxType.values[t.type];
      if (ty == TxType.income) incomes[monthIdx] += t.amount;
      if (ty == TxType.expense) expenses[monthIdx] += t.amount;
    }
    final maxVal =
        math.max(incomes.reduce(math.max), expenses.reduce(math.max));

    final currentExpense = expenses[monthCount - 1];
    final prevExpense = monthCount > 1 ? expenses[monthCount - 2] : 0;
    final deltaPct = prevExpense > 0
        ? ((currentExpense - prevExpense) / prevExpense * 100).round()
        : 0;

    return [
      _ChartCard(
        title: Tr.of(context).incomeVsForPeriod(periodName),
        value: '',
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxVal * 1.2 + 1,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => const FlLine(
                  color: Color(0xFFECECEC),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final month = DateTime(rangeStart.year,
                          rangeStart.month + v.toInt(), 1);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('LLL', Localizations.localeOf(context).languageCode).format(month),
                          style: TextStyle(
                              color: context.faintText, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < monthCount; i++)
                      FlSpot(i.toDouble(), incomes[i]),
                  ],
                  color: AppColors.limeAccent,
                  isCurved: true,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.limeAccent,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.lime.withValues(alpha: 0.2),
                  ),
                ),
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < monthCount; i++)
                      FlSpot(i.toDouble(), expenses[i]),
                  ],
                  color: AppColors.danger,
                  isCurved: true,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.danger,
                      strokeWidth: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: AppColors.limeAccent),
                const SizedBox(width: 6),
                Text(Tr.of(context).income,
                    style: TextStyle(
                        color: context.primaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: AppColors.danger),
                const SizedBox(width: 6),
                Text(Tr.of(context).expense,
                    style: TextStyle(
                        color: context.primaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _TrendStat(
              label: Tr.of(context).expenseThisMonth,
              value: formatMoney(currentExpense, currency),
              accent: AppColors.danger,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TrendStat(
              label: Tr.of(context).vsPrevMonth,
              value: '${deltaPct >= 0 ? '+' : ''}$deltaPct%',
              accent: deltaPct > 0 ? AppColors.limeAccent : AppColors.danger,
            ),
          ),
        ],
      ),
    ];
  }

  // ─────────────────────── Flows ───────────────────────
  List<Widget> _flowsView(
    List<db.Transaction> txs,
    List<db.Category> cats,
    String currency,
    String periodName,
  ) {
    final incomeByCat = <int, double>{};
    final expenseByCat = <int, double>{};
    var totalIncome = 0.0;
    var totalExpense = 0.0;

    for (final t in txs) {
      final ty = TxType.values[t.type];
      if (ty == TxType.income) {
        incomeByCat.update(t.categoryId ?? -1, (v) => v + t.amount,
            ifAbsent: () => t.amount);
        totalIncome += t.amount;
      } else if (ty == TxType.expense) {
        expenseByCat.update(t.categoryId ?? -1, (v) => v + t.amount,
            ifAbsent: () => t.amount);
        totalExpense += t.amount;
      }
    }

    final incomeSorted = incomeByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final expenseSorted = expenseByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final net = totalIncome - totalExpense;

    return [
      _ChartCard(
        title:
            '${Tr.of(context).cashFlowMonthPrefix}$periodName',
        value: '',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _FlowSide(
                    label: Tr.of(context).incomeUpper,
                    total: formatMoney(totalIncome, currency),
                    color: AppColors.limeAccent,
                    alignEnd: false,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Icon(Icons.arrow_forward,
                      color: context.faintText, size: 20),
                ),
                Expanded(
                  child: _FlowSide(
                    label: Tr.of(context).expenseUpper,
                    total: formatMoney(totalExpense, currency),
                    color: AppColors.danger,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: net >= 0
                    ? AppColors.lime.withValues(alpha: 0.2)
                    : AppColors.danger.withValues(alpha: 0.22),
                border: Border.all(
                  color: (net >= 0
                          ? AppColors.limeAccent
                          : AppColors.danger)
                      .withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(Tr.of(context).netUpper,
                      style: TextStyle(
                          color: context.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const Spacer(),
                  Text(
                    (net >= 0 ? '+' : '−') + formatMoney(net, currency),
                    style: TextStyle(
                      color: net >= 0
                          ? AppColors.limeAccent
                          : AppColors.danger,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (incomeSorted.isNotEmpty)
        _ChartCard(
          title: Tr.of(context).topIncomeSources,
          value: '',
          child: Column(
            children: [
              for (final e in incomeSorted.take(5))
                _FlowRow(
                  name: cats
                          .where((c) => c.id == e.key)
                          .map((c) => Tr.of(context).categoryName(c.name))
                          .firstOrNull ??
                      Tr.of(context).other,
                  amount: e.value,
                  currency: currency,
                  isIncome: true,
                  fraction:
                      totalIncome > 0 ? e.value / totalIncome : 0,
                ),
            ],
          ),
        ),
      const SizedBox(height: 16),
      if (expenseSorted.isNotEmpty)
        _ChartCard(
          title: Tr.of(context).topExpenses,
          value: '',
          child: Column(
            children: [
              for (final e in expenseSorted.take(5))
                _FlowRow(
                  name: cats
                          .where((c) => c.id == e.key)
                          .map((c) => Tr.of(context).categoryName(c.name))
                          .firstOrNull ??
                      Tr.of(context).other,
                  amount: e.value,
                  currency: currency,
                  isIncome: false,
                  fraction:
                      totalExpense > 0 ? e.value / totalExpense : 0,
                ),
            ],
          ),
        ),
    ];
  }

  Widget _legendItem({
    required Color color,
    required String name,
    required int percent,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: TextStyle(color: context.mutedText, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$percent%',
          style: TextStyle(
              color: context.primaryText,
              fontSize: 11,
              fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  static const _palette = [
    AppColors.lime,
    AppColors.danger,
    AppColors.info,
    AppColors.warning,
    AppColors.violet,
  ];
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.value,
    required this.child,
  });
  final String title;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color: context.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: context.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.fraction,
    required this.total,
    required this.currency,
  });

  final db.Category? category;
  final double amount;
  final double fraction;
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (amount / total * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ColorWellIcon(
              color: category != null
                  ? Color(category!.color)
                  : const Color(0xFF8A94A6),
              icon: category != null
                  ? lucideByKey(category!.icon)
                  : Icons.circle,
              size: 30,
              iconSize: 14,
              radius: 10,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category != null
                    ? Tr.of(context).categoryName(category!.name)
                    : Tr.of(context).other,
                style: TextStyle(
                    color: context.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              formatMoney(amount, currency),
              style: TextStyle(
                color: context.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(
                '$percent%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: context.faintText, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: context.progressTrack,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: category != null
                    ? Color(category!.color).asVivid
                    : AppColors.lime,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendStat extends StatelessWidget {
  const _TrendStat({
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: context.mutedText, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowSide extends StatelessWidget {
  const _FlowSide({
    required this.label,
    required this.total,
    required this.color,
    required this.alignEnd,
  });
  final String label;
  final String total;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(
          total,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.name,
    required this.amount,
    required this.currency,
    required this.isIncome,
    required this.fraction,
  });
  final String name;
  final double amount;
  final String currency;
  final bool isIncome;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.limeAccent : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                      color: context.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                (isIncome ? '+' : '−') + formatMoney(amount, currency),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: context.progressTrack,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
