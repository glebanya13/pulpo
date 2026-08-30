import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../data/db/enums.dart';
import '../data/repositories/providers.dart';
import '../data/repositories/settings_service.dart';
import 'l10n/tr.dart';
import 'utils/money_format.dart';
import 'widget_snapshot.dart';

const kHomeWidgetAndroidName = 'PulpoWidgetProvider';
const kHomeWidgetAndroidBudgetName = 'PulpoBudgetWidgetProvider';
const kHomeWidgetAndroidChartName = 'PulpoChartWidgetProvider';
const kHomeWidgetIosName = 'PulpoWidget';
const kHomeWidgetIosBudgetName = 'PulpoBudgetWidget';
const kHomeWidgetIosChartName = 'PulpoChartWidget';

const kHomeWidgetAppGroup = 'group.com.pulpo.widget';
const _homeWidgetDebounce = Duration(milliseconds: 700);

Future<void> configureHomeWidget() async {
  if (kIsWeb) return;
  // App Group `group.com.pulpo.widget` must exist on the Apple Developer
  // App ID + provisioning profile before adding it to Runner.entitlements.
  // Until then, skip setAppGroupId so IPA signing stays green.
  if (Platform.isIOS) return;
  try {
    await HomeWidget.setAppGroupId(kHomeWidgetAppGroup);
  } catch (e, st) {
    debugPrint('home widget group: $e\n$st');
  }
}

class HomeWidgetBinder extends ConsumerStatefulWidget {
  const HomeWidgetBinder({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HomeWidgetBinder> createState() => _HomeWidgetBinderState();
}

class _HomeWidgetBinderState extends ConsumerState<HomeWidgetBinder> {
  String? _lastPayload;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleSync());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(_homeWidgetDebounce, () {
      if (!mounted) return;
      unawaited(_syncNow());
    });
  }

  Future<void> _syncNow() async {
    final total = ref.read(totalBalanceProvider);
    final settings = ref.read(settingsControllerProvider);
    final currency = settings.baseCurrency;
    final locale = settings.locale;
    final txs = ref.read(allTransactionsProvider).valueOrNull ?? const [];
    final budgets = ref.read(budgetsProvider).valueOrNull ?? const [];
    final cats = ref.read(categoriesProvider).valueOrNull ?? const [];

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    var spent = 0.0;
    for (final t in txs) {
      if (t.date.isBefore(monthStart)) continue;
      if (TxType.values[t.type] != TxType.expense) continue;
      spent += t.amount;
    }

    final tr = Tr.fromLang(locale);
    final snap = buildWidgetSnapshot(
      totalBalance: total,
      formattedBalance: formatMoney(total, currency),
      formattedSpent: formatMoney(spent, currency),
      currency: currency,
      txs: txs,
      budgets: budgets,
      formatMoney: formatMoney,
      categoryLabel: (id) {
        if (id == null) return tr.other;
        for (final c in cats) {
          if (c.id == id) return tr.categoryName(c.name);
        }
        return tr.other;
      },
    );

    final payload = [
      snap.balance,
      snap.spent,
      snap.budgetLeft,
      '${snap.budgetPercent}',
      snap.monthLabel,
      snap.dailyBars.join(','),
      encodeCategoryShortcuts(snap.categoryShortcuts),
    ].join('|');

    if (payload == _lastPayload) return;
    _lastPayload = payload;
    await _push(tr: tr, snap: snap);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(totalBalanceProvider, (_, _) => _scheduleSync());
    ref.listen(
      settingsControllerProvider.select((s) => '${s.baseCurrency}|${s.locale}'),
      (_, _) => _scheduleSync(),
    );
    ref.listen(allTransactionsProvider, (_, _) => _scheduleSync());
    ref.listen(budgetsProvider, (_, _) => _scheduleSync());
    ref.listen(categoriesProvider, (_, _) => _scheduleSync());

    return widget.child;
  }

  Future<void> _push({
    required Tr tr,
    required WidgetSnapshot snap,
  }) async {
    if (kIsWeb) return;
    // iOS WidgetKit needs App Groups on the signing profile; Android works now.
    if (Platform.isIOS) return;
    try {
      await HomeWidget.saveWidgetData<String>('balance', snap.balance);
      await HomeWidget.saveWidgetData<String>('spent', snap.spent);
      await HomeWidget.saveWidgetData<String>(
          'balance_label', tr.totalBalance);
      await HomeWidget.saveWidgetData<String>(
          'spent_label', tr.spentThisMonth);
      await HomeWidget.saveWidgetData<String>('budget_left', snap.budgetLeft);
      await HomeWidget.saveWidgetData<String>(
          'budget_left_label', tr.widgetBudgetLeft);
      await HomeWidget.saveWidgetData<String>(
          'budget_percent', '${snap.budgetPercent}');
      await HomeWidget.saveWidgetData<String>('month_label', snap.monthLabel);
      await HomeWidget.saveWidgetData<String>(
          'expense_label', tr.widgetMonthExpense);
      await HomeWidget.saveWidgetData<String>(
          'daily_bars', snap.dailyBars.join(','));
      await HomeWidget.saveWidgetData<String>(
          'categories_json', encodeCategoryShortcuts(snap.categoryShortcuts));

      for (final name in [
        kHomeWidgetAndroidName,
        kHomeWidgetAndroidBudgetName,
        kHomeWidgetAndroidChartName,
      ]) {
        await HomeWidget.updateWidget(
          name: name,
          androidName: name,
          qualifiedAndroidName: 'com.pulpo.android.$name',
        );
      }
    } catch (e, st) {
      debugPrint('home widget update: $e\n$st');
    }
  }
}

String formatWidgetMonthLabel(String yyyyMm, String locale) {
  try {
    final parts = yyyyMm.split('-');
    if (parts.length != 2) return yyyyMm;
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    return DateFormat('yyyy-MM', locale).format(d);
  } catch (_) {
    return yyyyMm;
  }
}
