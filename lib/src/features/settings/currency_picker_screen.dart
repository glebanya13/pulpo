import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
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

  static const _popular = [
    ('EUR', 'Euro', '€', '🇪🇸'),
    ('MXN', 'Peso mexicano', '\$', '🇲🇽'),
    ('ARS', 'Peso argentino', '\$', '🇦🇷'),
    ('COP', 'Peso colombiano', '\$', '🇨🇴'),
    ('CLP', 'Peso chileno', '\$', '🇨🇱'),
    ('PEN', 'Sol peruano', 'S/', '🇵🇪'),
    ('USD', 'Dólar estadounidense', '\$', '🇺🇸'),
    ('UYU', 'Peso uruguayo', '\$', '🇺🇾'),
    ('PYG', 'Guaraní paraguayo', '₲', '🇵🇾'),
    ('BOB', 'Boliviano', 'Bs', '🇧🇴'),
    ('VES', 'Bolívar venezolano', 'Bs.', '🇻🇪'),
    ('CRC', 'Colón costarricense', '₡', '🇨🇷'),
    ('DOP', 'Peso dominicano', '\$', '🇩🇴'),
    ('GTQ', 'Quetzal guatemalteco', 'Q', '🇬🇹'),
    ('HNL', 'Lempira hondureño', 'L', '🇭🇳'),
    ('NIO', 'Córdoba nicaragüense', 'C\$', '🇳🇮'),
    ('CUP', 'Peso cubano', '\$', '🇨🇺'),
    ('XAF', 'Franco CFA', 'FCFA', '🇬🇶'),
  ];

  bool _match(String code, String name) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return code.toLowerCase().contains(q) || name.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final current = ref.watch(settingsControllerProvider).baseCurrency;

    final popular = _popular
        .where((c) => _match(c.$1, c.$2))
        .toList(growable: false);

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
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.search,
                      size: 18, color: AppColors.textFaint),
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
            const SizedBox(height: 16),
            if (popular.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(tr.popularUpper,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                    )),
              ),
              _List(
                items: popular,
                current: current,
                onPick: (code) async {
                  await ref
                      .read(settingsServiceProvider)
                      .setBaseCurrency(code);
                  ref.invalidate(settingsControllerProvider);
                  if (context.mounted) context.pop();
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.items,
    required this.current,
    required this.onPick,
  });
  final List<(String, String, String, String)> items;
  final String current;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _Row(
                code: items[i].$1,
                name: items[i].$2,
                symbol: items[i].$3,
                flag: items[i].$4,
                selected: items[i].$1 == current,
                onTap: () => onPick(items[i].$1),
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
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.selected,
    required this.onTap,
  });
  final String code;
  final String name;
  final String symbol;
  final String flag;
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
              child: Center(child: Text(flag, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('$code · $symbol',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textFaint)),
                ],
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
