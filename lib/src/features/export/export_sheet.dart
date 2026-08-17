import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../reports/stats_period.dart';
import 'export_service.dart';

Future<void> showExportSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => const _ExportSheet(),
  );
}

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet();

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final range = ref.watch(statsPeriodProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr.exportPeriod,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.primaryText,
              )),
          const SizedBox(height: 12),
          if (_busy) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in StatsPeriodKind.values)
                if (k != StatsPeriodKind.custom)
                  _Chip(
                    label: _label(tr, k),
                    active: range.kind == k,
                    onTap: _busy
                        ? null
                        : () =>
                            ref.read(statsPeriodProvider.notifier).setKind(k),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : () => _go(ExportFormat.csv),
            child: Text(tr.exportCsv),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _go(ExportFormat.excel),
            child: Text(tr.exportExcel),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _go(ExportFormat.pdf),
            child: Text(tr.exportPdf),
          ),
        ],
      ),
    );
  }

  Future<void> _go(ExportFormat format) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final range = ref.read(statsPeriodProvider);
      final txs = await ref.read(
        transactionsInRangeProvider((start: range.start, end: range.end))
            .future,
      );
      final filtered = txs
          .where((t) => TxType.values[t.type] != TxType.transfer)
          .toList();
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await exportService.shareTransactions(
        txs: filtered,
        format: format,
        start: range.start,
        end: range.end,
        shareOrigin: origin,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, this.onTap});
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (context.isDark ? AppColors.ink3 : AppColors.ink)
              : context.scaffoldBg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : context.primaryText,
          ),
        ),
      ),
    );
  }
}

String _label(Tr tr, StatsPeriodKind k) {
  switch (k) {
    case StatsPeriodKind.thisMonth:
      return tr.periodThisMonth;
    case StatsPeriodKind.lastMonth:
      return tr.periodLastMonth;
    case StatsPeriodKind.months3:
      return tr.period3m;
    case StatsPeriodKind.months6:
      return tr.period6m;
    case StatsPeriodKind.thisYear:
      return tr.periodThisYear;
    case StatsPeriodKind.lastYear:
      return tr.periodLastYear;
    case StatsPeriodKind.custom:
      return tr.periodCustom;
  }
}
