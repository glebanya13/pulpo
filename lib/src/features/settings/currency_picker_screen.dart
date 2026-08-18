import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/currencies.dart';
import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';

class CurrencyPickerScreen extends ConsumerStatefulWidget {
  const CurrencyPickerScreen({super.key});

  @override
  ConsumerState<CurrencyPickerScreen> createState() =>
      _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends ConsumerState<CurrencyPickerScreen> {
  String _query = '';

  bool _match(AppCurrency c) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return c.country.toLowerCase().contains(q) ||
        c.code.toLowerCase().contains(q) ||
        c.symbol.toLowerCase().contains(q) ||
        c.title.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final currentCode = ref.watch(settingsControllerProvider).baseCurrency;
    final currentCountry =
        ref.watch(settingsControllerProvider).baseCurrencyCountry;
    final items = appCurrencies.where(_match).toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RoundIconButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: () => context.pop(),
                ),
                Text(tr.baseCurrency,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.search,
                      size: 18, color: context.faintText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: tr.searchCurrency,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: context.surface,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      _Row(
                        item: items[i],
                        selected: items[i].country == currentCountry &&
                            items[i].code == currentCode,
                        onTap: () async {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .setBaseCurrency(
                                items[i].code,
                                country: items[i].country,
                              );
                          if (context.mounted) context.pop();
                        },
                      ),
                      if (i != items.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(left: 66, right: 16),
                          child: Divider(height: 1, color: AppColors.divider),
                        ),
                    ],
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

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final AppCurrency item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lime.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? AppColors.lime : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Center(
                  child: Text(item.flag, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (selected)
              const Icon(LucideIcons.check,
                  color: AppColors.limeAccent, size: 20),
          ],
        ),
      ),
    );
  }
}
