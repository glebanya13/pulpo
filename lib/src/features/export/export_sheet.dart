import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../reports/stats_period.dart';
import 'export_service.dart';

Future<void> showExportSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => const _ExportSheet(),
  );
}

class _ExportSheet extends ConsumerWidget {
  const _ExportSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in StatsPeriodKind.values)
                if (k != StatsPeriodKind.custom)
                  _Chip(
                    label: _label(tr, k),
                    active: range.kind == k,
                    onTap: () =>
                        ref.read(statsPeriodProvider.notifier).setKind(k),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _go(context, ref, ExportFormat.csv),
            child: Text(tr.exportCsv),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _go(context, ref, ExportFormat.excel),
            child: Text(tr.exportExcel),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _go(context, ref, ExportFormat.pdf),
            child: Text(tr.exportPdf),
          ),
        ],
      ),
    );
  }

  Future<void> _go(
    BuildContext context,
    WidgetRef ref,
    ExportFormat format,
  ) async {
    final range = ref.read(statsPeriodProvider);
    final txs = ref
            .read(transactionsInRangeProvider(
                (start: range.start, end: range.end)))
            .valueOrNull ??
        const [];
    final filtered = txs
        .where((t) => TxType.values[t.type] != TxType.transfer)
        .toList();
    await exportService.shareTransactions(
      txs: filtered,
      format: format,
      start: range.start,
      end: range.end,
    );
    if (context.mounted) Navigator.pop(context);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.bg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.ink,
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
