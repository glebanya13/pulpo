import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../data/db/enums.dart';
import '../data/repositories/providers.dart';
import '../data/repositories/settings_service.dart';
import 'l10n/tr.dart';
import 'utils/money_format.dart';

const kHomeWidgetAppGroup = 'group.com.pulpo.app';
const kHomeWidgetIosName = 'PulpoWidget';
const kHomeWidgetAndroidName = 'PulpoWidgetProvider';

Future<void> configureHomeWidget() async {
  if (kIsWeb) return;
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

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(totalBalanceProvider);
    final currency = ref.watch(settingsControllerProvider).baseCurrency;
    final locale = ref.watch(settingsControllerProvider).locale;
    final txs = ref.watch(allTransactionsProvider).valueOrNull ?? const [];

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    var spent = 0.0;
    for (final t in txs) {
      if (t.date.isBefore(monthStart)) continue;
      if (TxType.values[t.type] != TxType.expense) continue;
      spent += t.amount;
    }

    final tr = Tr.fromLang(locale);
    final payload = [
      formatMoney(total, currency),
      formatMoney(spent, currency),
      tr.totalBalance,
      tr.spentThisMonth,
      locale,
    ].join('|');

    if (payload != _lastPayload) {
      _lastPayload = payload;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _push(
          balance: formatMoney(total, currency),
          spent: formatMoney(spent, currency),
          balanceLabel: tr.totalBalance,
          spentLabel: tr.spentThisMonth,
        );
      });
    }

    return widget.child;
  }

  Future<void> _push({
    required String balance,
    required String spent,
    required String balanceLabel,
    required String spentLabel,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('balance', balance);
      await HomeWidget.saveWidgetData<String>('spent', spent);
      await HomeWidget.saveWidgetData<String>('balance_label', balanceLabel);
      await HomeWidget.saveWidgetData<String>('spent_label', spentLabel);
      await HomeWidget.updateWidget(
        name: kHomeWidgetAndroidName,
        androidName: kHomeWidgetAndroidName,
        iOSName: kHomeWidgetIosName,
        qualifiedAndroidName: 'com.pulpo.android.$kHomeWidgetAndroidName',
      );
    } catch (e, st) {
      debugPrint('home widget update: $e\n$st');
    }
  }
}
