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

Future<void> configureHomeWidget() async {
  // iOS App Groups require regenerating the Codemagic/"Monedero" provisioning
  // profile after enabling the capability on com.pulpo.app. Until then,
  // keep Runner.entitlements free of application-groups so IPA signing works.
  if (kIsWeb) return;
}

class HomeWidgetBinder extends ConsumerStatefulWidget {
  const HomeWidgetBinder({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HomeWidgetBinder> createState() => _HomeWidgetBinderState();
}

class _HomeWidgetBinderState extends ConsumerState<HomeWidgetBinder> {
  String? _lastPayload;

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(totalBalanceProvider);
    final currency = ref.watch(settingsControllerProvider).baseCurrency;
    final locale = ref.watch(settingsControllerProvider).locale;
    final txs = ref.watch(allTransactionsProvider).valueOrNull ?? const [];
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];

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

    if (payload != _lastPayload) {
      _lastPayload = payload;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _push(tr: tr, snap: snap);
      });
    }

    return widget.child;
  }

  Future<void> _push({
    required Tr tr,
    required WidgetSnapshot snap,
  }) async {
    if (kIsWeb || Platform.isIOS) return;
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
