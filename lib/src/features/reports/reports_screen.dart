import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/ai/ai_errors.dart';
import '../../core/ai/ai_models.dart';
import '../../core/ai/pulpo_ai_service.dart';
import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/pressable.dart';
import '../../widgets/common.dart';
import '../../widgets/pro_badge.dart';
import '../../widgets/reset_scroll_when_obscured.dart';
import 'custom_period_picker.dart';
import 'stats_period.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _tab = 0;
  String? _aiInsight;
  String? _aiInsightForPeriod;
  bool _aiInsightBusy = false;

  void _resetToInitial() {
    ref
        .read(statsPeriodProvider.notifier)
        .setKind(StatsPeriodKind.thisMonth);
    setState(() {
      _tab = 0;
      _aiInsight = null;
      _aiInsightForPeriod = null;
      _aiInsightBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final tabs = [tr.tabOverview, tr.tabTrends, tr.tabFlows];
    final currency = ref.watch(settingsControllerProvider).baseCurrency;
    final range = ref.watch(statsPeriodProvider);
    final txsAsync = ref.watch(
      transactionsInRangeProvider((start: range.start, end: range.end)),
    );
    final catsAsync = ref.watch(categoriesProvider);
    final now = DateTime.now();
    final monthCount = monthsCovered(range.start, range.end);

    void retryLoad() {
      ref.invalidate(
        transactionsInRangeProvider((start: range.start, end: range.end)),
      );
      ref.invalidate(categoriesProvider);
    }

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
    final isPro = ref.watch(proControllerProvider).isPro;
    final customRangeLabel = range.kind == StatsPeriodKind.custom
        ? '${DateFormat('d MMM', Localizations.localeOf(context).languageCode).format(range.start)} – ${DateFormat('d MMM', Localizations.localeOf(context).languageCode).format(range.end.subtract(const Duration(days: 1)))}'
        : null;

    return ResetScrollWhenObscured(
      tabPath: '/reports',
      onBecameVisible: _resetToInitial,
      builder: (context, scroll) {
        final pad = AppSpacing.tabPagePadding(context).copyWith(bottom: 0);
        return StickyScrollPage(
          useSafeArea: false,
          controller: scroll,
          padding: pad,
          headerGap: 16,
          fillViewport: true,
          header: ScreenTitlePill(
            title: tr.analytics,
            subtitle: tr.analyticsSubtitle,
            large: true,
            expand: true,
            trailing: const HeaderSupportActions(dense: true),
          ),
          children: [
        _PeriodDropdownButton(
          label: customRangeLabel ?? periodName,
          onTap: () => _openPeriodPicker(
            context: context,
            ref: ref,
            tr: tr,
            current: range.kind,
            isPro: isPro,
            periodLabel: periodLabel,
          ),
        ),
        const SizedBox(height: 12),
        _ReportsSegmentedTabs(
          labels: tabs,
          index: _tab,
          locked: isPro ? const {} : const {1, 2},
          onSelect: (i) async {
            if ((i == 1 || i == 2) && !isPro) {
              await openPaywall(
                context,
                i == 1 ? ProGate.trends : ProGate.flows,
              );
              return;
            }
            setState(() => _tab = i);
          },
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: context.surface,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset =
                      AppSpacing.tabScrollBottomInset(context);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: AsyncValuesGate(
                        values: [txsAsync, catsAsync],
                        onRetry: retryLoad,
                        child: Builder(
                          builder: (context) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ..._buildTabContent(
                                  txs: txsAsync.requireValue,
                                  cats: catsAsync.requireValue,
                                  now: now,
                                  rangeStart: range.start,
                                  rangeEnd: range.end,
                                  monthCount: monthCount,
                                  currency: currency,
                                  periodName: periodName,
                                  periodKind: range.kind,
                                ),
                                SizedBox(height: bottomInset),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
          ],
        );
      },
    );
  }

  Future<void> _openPeriodPicker({
    required BuildContext context,
    required WidgetRef ref,
    required Tr tr,
    required StatsPeriodKind current,
    required bool isPro,
    required String Function(StatsPeriodKind) periodLabel,
  }) async {
    await showAppBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: AppSpacing.sheetOnTabScreen(ctx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.faintText.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  tr.choosePeriod,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final k in StatsPeriodKind.values)
                _PeriodSheetTile(
                  label: periodLabel(k),
                  selected: current == k,
                  locked: !_isFreePeriod(k) && !isPro,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (k == StatsPeriodKind.custom) {
                      if (!isPro) {
                        await openPaywall(context, ProGate.analytics);
                        return;
                      }
                      await pickCustomStatsPeriod(context, ref);
                      return;
                    }
                    if (!_isFreePeriod(k) && !isPro) {
                      await openPaywall(context, ProGate.analytics);
                      return;
                    }
                    ref.read(statsPeriodProvider.notifier).setKind(k);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isFreePeriod(StatsPeriodKind k) =>
      k == StatsPeriodKind.thisMonth || k == StatsPeriodKind.lastMonth;

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
        return _trendsView(
          txs,
          rangeStart,
          rangeEnd,
          monthCount,
          currency,
          periodName,
          periodKind,
        );
      case 2:
        return _flowsView(txs, cats, currency, periodName);
      default:
        return _overviewView(
            txs, cats, now, rangeStart, monthCount, currency, periodName);
    }
  }

  // ─────────────────────── Overview ───────────────────────
  Future<void> _generateInsight({
    required String periodName,
    required String currency,
    required double totalExpense,
    required double totalIncome,
    required List<({String name, double amount})> topCategories,
  }) async {
    final tr = Tr.of(context);
    if (!await requireAi(context, ref)) return;
    if (!mounted) return;
    setState(() => _aiInsightBusy = true);
    try {
      final locale = ref.read(settingsControllerProvider).locale;
      final result = await ref.read(pulpoAiServiceProvider).generatePeriodInsight(
            PeriodInsightInput(
              periodLabel: periodName,
              currency: currency,
              totalExpense: totalExpense,
              totalIncome: totalIncome,
              topCategories: topCategories,
            ),
            locale: locale,
          );
      if (!mounted) return;
      setState(() {
        _aiInsight = result.text;
        _aiInsightForPeriod = periodName;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeAiError(tr, e))),
      );
    } finally {
      if (mounted) setState(() => _aiInsightBusy = false);
    }
  }

  List<Widget> _overviewView(
    List<db.Transaction> txs,
    List<db.Category> cats,
    DateTime now,
    DateTime rangeStart,
    int monthCount,
    String currency,
    String periodName,
  ) {
    final monthlyExpense = List<double>.filled(monthCount, 0);
    final monthlyIncome = List<double>.filled(monthCount, 0);
    final expenseByCat = <int, double>{};
    final incomeByCat = <int, double>{};
    var expenseTotal = 0.0;
    var incomeTotal = 0.0;

    for (final t in txs) {
      final monthIdx = (t.date.year - rangeStart.year) * 12 +
          (t.date.month - rangeStart.month);
      if (monthIdx < 0 || monthIdx >= monthCount) continue;

      final type = TxType.values[t.type];
      if (type == TxType.income) {
        monthlyIncome[monthIdx] += t.amount;
        incomeByCat.update(t.categoryId ?? -1, (v) => v + t.amount,
            ifAbsent: () => t.amount);
        incomeTotal += t.amount;
      } else if (type == TxType.expense) {
        monthlyExpense[monthIdx] += t.amount;
        expenseByCat.update(t.categoryId ?? -1, (v) => v + t.amount,
            ifAbsent: () => t.amount);
        expenseTotal += t.amount;
      }
    }

    final expensePeriodTotal =
        monthlyExpense.fold<double>(0, (a, b) => a + b);
    final incomePeriodTotal = monthlyIncome.fold<double>(0, (a, b) => a + b);
    final expenseDonut = expenseByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final incomeDonut = incomeByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final tr = Tr.of(context);
    final topCategories = <({String name, double amount})>[];
    for (final e in expenseDonut.take(8)) {
      final cat = cats.where((c) => c.id == e.key).firstOrNull;
      final name = cat != null ? tr.categoryName(cat.name) : tr.other;
      topCategories.add((name: name, amount: e.value));
    }

    if (_aiInsightForPeriod != null && _aiInsightForPeriod != periodName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _aiInsight = null;
          _aiInsightForPeriod = null;
        });
      });
    }

    return [
      _AiInsightCard(
        insight: _aiInsight,
        busy: _aiInsightBusy,
        showPro: !ref.watch(proControllerProvider).isPro,
        onGenerate: () async {
          if (!ref.read(proControllerProvider).isPro) {
            await openPaywall(context, ProGate.analytics);
            return;
          }
          await _generateInsight(
            periodName: periodName,
            currency: currency,
            totalExpense: expenseTotal,
            totalIncome: incomeTotal,
            topCategories: topCategories,
          );
        },
      ),
      const SizedBox(height: 16),
      _overviewBarChartCard(
        title: tr.incomeForPeriod(periodName),
        emptyLabel: tr.noIncomeForPeriod(periodName),
        monthly: monthlyIncome,
        total: incomePeriodTotal,
        activeBarColor: AppColors.limeAccent,
        rangeStart: rangeStart,
        monthCount: monthCount,
        currency: currency,
      ),
      const SizedBox(height: 16),
      _overviewBarChartCard(
        title: tr.expensesForPeriod(periodName),
        emptyLabel: tr.noExpensesForPeriod(periodName),
        monthly: monthlyExpense,
        total: expensePeriodTotal,
        activeBarColor: _chartBarColor,
        rangeStart: rangeStart,
        monthCount: monthCount,
        currency: currency,
      ),
      const SizedBox(height: 16),
      _overviewCategoriesCard(
        title: '${tr.incomeByCategoriesMonthPrefix}$periodName',
        emptyLabel: tr.noIncomeForPeriod(periodName),
        donutData: incomeDonut,
        periodTotal: incomeTotal,
        cats: cats,
        currency: currency,
      ),
      const SizedBox(height: 16),
      _overviewCategoriesCard(
        title: '${tr.expensesByCategoriesMonthPrefix}$periodName',
        emptyLabel: tr.noExpensesForPeriod(periodName),
        donutData: expenseDonut,
        periodTotal: expenseTotal,
        cats: cats,
        currency: currency,
      ),
    ];
  }

  Widget _overviewBarChartCard({
    required String title,
    required String emptyLabel,
    required List<double> monthly,
    required double total,
    required Color activeBarColor,
    required DateTime rangeStart,
    required int monthCount,
    required String currency,
  }) {
    final maxMonthly = monthly.isEmpty ? 0.0 : monthly.reduce(math.max);
    return _ChartCard(
      title: title,
      value: formatMoney(total, currency),
      child: total <= 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                emptyLabel,
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
                          final month = DateTime(
                              rangeStart.year, rangeStart.month + v.toInt(), 1);
                          final isCurrent = v.toInt() == monthCount - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat(
                                      'LLL',
                                      Localizations.localeOf(context)
                                          .languageCode)
                                  .format(month),
                              style: TextStyle(
                                color: isCurrent
                                    ? activeBarColor
                                    : context.faintText,
                                fontSize: 11,
                                fontWeight: isCurrent
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
                                ? activeBarColor
                                : context.progressTrack,
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
    );
  }

  Widget _overviewCategoriesCard({
    required String title,
    required String emptyLabel,
    required List<MapEntry<int, double>> donutData,
    required double periodTotal,
    required List<db.Category> cats,
    required String currency,
  }) {
    final maxCatVal = donutData.isEmpty ? 1.0 : donutData.first.value;
    return _ChartCard(
      title: title,
      value: '',
      child: donutData.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                emptyLabel,
                style: TextStyle(color: context.mutedText, fontSize: 14),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatMoney(periodTotal, currency),
                  style: TextStyle(
                    color: context.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  Tr.of(context).totalWord,
                  style: TextStyle(
                    color: context.faintText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                _CategoryDonut(
                  segments: [
                    for (var i = 0; i < donutData.length; i++)
                      _StackSegment(
                        color: _pieColorForCategory(
                          cats
                              .where((c) => c.id == donutData[i].key)
                              .firstOrNull,
                          i,
                        ),
                        value: donutData[i].value,
                      ),
                  ],
                  centerLabel: formatMoney(periodTotal, currency),
                  centerHint: Tr.of(context).totalWord,
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < donutData.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _CategoryRow(
                    category: cats
                        .where((c) => c.id == donutData[i].key)
                        .firstOrNull,
                    amount: donutData[i].value,
                    fraction: donutData[i].value / maxCatVal,
                    total: periodTotal,
                    currency: currency,
                    barColor: _pieColorForCategory(
                      cats
                          .where((c) => c.id == donutData[i].key)
                          .firstOrNull,
                      i,
                    ),
                  ),
                ],
              ],
            ),
    );
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
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: context.divider,
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
                getDrawingHorizontalLine: (v) => FlLine(
                  color: context.divider,
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

  /// Palette for the category pie — never uses app lime (#CDFF3A family).
  static const _pieFallback = <Color>[
    Color(0xFF5B8DEF),
    Color(0xFFFF6B6B),
    Color(0xFFFFB84E),
    Color(0xFFA78BFA),
    Color(0xFF4ECDC4),
    Color(0xFFFF8A5B),
    Color(0xFF6C8EFF),
    Color(0xFFE879A9),
  ];

  static Color _pieColorForCategory(db.Category? category, int index) {
    if (category == null) {
      return _pieFallback[index % _pieFallback.length];
    }
    return _withoutBrandLime(
      Color(category.color).asVivid,
      fallbackIndex: index,
    );
  }

  static Color _withoutBrandLime(Color c, {int fallbackIndex = 0}) {
    final hsl = HSLColor.fromColor(c);
    // Brand lime sits roughly hue ~70–95 with high lightness.
    final isLimeFamily = hsl.hue >= 55 &&
        hsl.hue <= 110 &&
        hsl.saturation > 0.35 &&
        hsl.lightness > 0.35;
    if (!isLimeFamily) return c;
    return _pieFallback[fallbackIndex % _pieFallback.length];
  }

  static const _chartBarColor = Color(0xFF5B8DEF);
}

class _StackSegment {
  const _StackSegment({required this.color, required this.value});
  final Color color;
  final double value;
}

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({
    required this.segments,
    required this.centerLabel,
    required this.centerHint,
  });

  final List<_StackSegment> segments;
  final String centerLabel;
  final String centerHint;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 58,
              startDegreeOffset: -90,
              sections: [
                for (final seg in segments)
                  if (seg.value > 0)
                    PieChartSectionData(
                      value: seg.value,
                      color: seg.color,
                      radius: 34,
                      showTitle: false,
                    ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.primaryText,
                ),
              ),
              Text(
                centerHint,
                style: TextStyle(
                  fontSize: 11,
                  color: context.faintText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodDropdownButton extends StatelessWidget {
  const _PeriodDropdownButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.calendar,
                size: 16,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 18,
              color: context.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsSegmentedTabs extends StatelessWidget {
  const _ReportsSegmentedTabs({
    required this.labels,
    required this.index,
    required this.onSelect,
    this.locked = const {},
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onSelect;
  final Set<int> locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              // Equal width — chrome PRO mark is compact.
              flex: 1,
              child: Pressable(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: index == i
                        ? (context.isDark ? AppColors.ink3 : AppColors.ink)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: index == i
                                    ? Colors.white
                                    : context.mutedText,
                              ),
                            ),
                          ),
                        ),
                        if (locked.contains(i)) ...[
                          const SizedBox(width: 4),
                          const ProChromeMark(size: 13),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodSheetTile extends StatelessWidget {
  const _PeriodSheetTile({
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lime.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: locked
                      ? proLockedTextColor(context)
                      : context.primaryText,
                ),
              ),
            ),
            if (locked)
              const ProBadge(dense: true)
            else if (selected)
              const Icon(LucideIcons.check, size: 18, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({
    required this.insight,
    required this.busy,
    required this.onGenerate,
    this.showPro = false,
  });

  final String? insight;
  final bool busy;
  final VoidCallback onGenerate;
  final bool showPro;

  static const _assistantDeep = Color(0xFF8B7CFF);

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final accent = AppColors.violet;
    final isDark = context.isDark;
    // На светлой карточке пастельный violet (#A78BFA) почти не виден.
    final actionColor = isDark ? accent : AppColors.brandPurple;
    final hintColor = isDark ? context.mutedText : AppColors.textSecondary;
    final lockedDim = showPro && isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _assistantDeep.withValues(alpha: context.isDark ? 0.28 : 0.16),
            accent.withValues(alpha: context.isDark ? 0.16 : 0.10),
            context.surface,
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: context.isDark ? 0.45 : 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 18,
                color: lockedDim ? accent.withValues(alpha: 0.55) : actionColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr.aiInsightTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: lockedDim
                        ? context.primaryText.withValues(alpha: 0.55)
                        : context.primaryText,
                  ),
                ),
              ),
              if (showPro) ...[
                const SizedBox(width: 8),
                const ProBadge(dense: true),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (insight == null)
            Text(
              tr.aiInsightHint,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: lockedDim
                    ? hintColor.withValues(alpha: 0.7)
                    : hintColor,
              ),
            )
          else
            Text(
              insight!,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: context.primaryText,
              ),
            ),
          const SizedBox(height: 12),
          Pressable(
            onTap: busy ? null : onGenerate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: actionColor.withValues(
                    alpha: busy
                        ? 0.4
                        : lockedDim
                            ? 0.35
                            : isDark
                                ? 0.85
                                : 0.55,
                  ),
                  width: 1.5,
                ),
                color: actionColor.withValues(
                  alpha: busy
                      ? 0.08
                      : lockedDim
                          ? 0.08
                          : isDark
                              ? 0.14
                              : 0.1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                busy ? tr.aiBusy : tr.aiInsightGenerate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: actionColor.withValues(
                    alpha: busy
                        ? 0.5
                        : lockedDim
                            ? 0.45
                            : 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    required this.barColor,
  });

  final db.Category? category;
  final double amount;
  final double fraction;
  final double total;
  final String currency;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (amount / total * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ColorWellIcon(
              color: barColor,
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
                color: barColor,
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
