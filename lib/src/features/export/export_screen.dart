import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../reports/custom_period_picker.dart';
import '../reports/stats_period.dart';
import 'export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final range = ref.watch(statsPeriodProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(first: tr.exportCsv, onBack: () => context.pop()),
            const SizedBox(height: 24),
            Text(
              tr.exportPeriod,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.mutedText,
              ),
            ),
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
                  _Chip(
                    label: _label(tr, k),
                    active: range.kind == k,
                    onTap: _busy
                        ? null
                        : () async {
                            if (k == StatsPeriodKind.custom) {
                              await pickCustomStatsPeriod(context, ref);
                              return;
                            }
                            ref
                                .read(statsPeriodProvider.notifier)
                                .setKind(k);
                          },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ScaledFilledButton(
              onPressed: _busy ? null : () => _go(ExportFormat.csv),
              child: Text(tr.exportCsv),
            ),
            const SizedBox(height: 8),
            ScaledOutlinedButton(
              onPressed: _busy ? null : () => _go(ExportFormat.excel),
              child: Text(tr.exportExcel),
            ),
            const SizedBox(height: 8),
            ScaledOutlinedButton(
              onPressed: _busy ? null : () => _go(ExportFormat.pdf),
              child: Text(tr.exportPdf),
            ),
            const SizedBox(height: 8),
            ScaledOutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final ok =
                          await requirePro(context, ref, ProGate.importCsv);
                      if (!ok || !context.mounted) return;
                      context.push('/settings/import');
                    },
              child: Text(tr.importCsv),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _go(ExportFormat format) async {
    if (_busy) return;
    if (format == ExportFormat.excel &&
        !await requirePro(context, ref, ProGate.excel)) {
      return;
    }
    if (format == ExportFormat.pdf &&
        !await requirePro(context, ref, ProGate.pdf)) {
      return;
    }
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
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
      await exportService.shareTransactions(
        txs: filtered,
        format: format,
        start: range.start,
        end: range.end,
        locale: ref.read(settingsControllerProvider).locale,
        shareOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.of(context).errorTitle)),
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
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (context.isDark ? AppColors.ink3 : AppColors.ink)
              : context.surface,
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
