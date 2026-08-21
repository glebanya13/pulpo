import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';
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
    final isPro = ref.watch(proControllerProvider).isPro;
    final periodName = _label(tr, range.kind);
    final customRangeLabel = range.kind == StatsPeriodKind.custom
        ? '${DateFormat('d MMM', Localizations.localeOf(context).languageCode).format(range.start)} – ${DateFormat('d MMM', Localizations.localeOf(context).languageCode).format(range.end.subtract(const Duration(days: 1)))}'
        : null;

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
            _PeriodDropdownButton(
              label: customRangeLabel ?? periodName,
              onTap: _busy
                  ? null
                  : () => _openPeriodPicker(
                        context: context,
                        current: range.kind,
                      ),
            ),
            const SizedBox(height: 24),
            ScaledFilledButton(
              onPressed: _busy ? null : () => _go(ExportFormat.csv),
              child: Text(tr.exportCsv),
            ),
            const SizedBox(height: 8),
            ScaledOutlinedButton(
              onPressed: _busy ? null : () => _go(ExportFormat.excel),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr.exportExcel),
                  if (!isPro) ...[
                    const SizedBox(width: 8),
                    const ProBadge(dense: true),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            ScaledOutlinedButton(
              onPressed: _busy ? null : () => _go(ExportFormat.pdf),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr.exportPdf),
                  if (!isPro) ...[
                    const SizedBox(width: 8),
                    const ProBadge(dense: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPeriodPicker({
    required BuildContext context,
    required StatsPeriodKind current,
  }) async {
    final tr = Tr.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
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
                    label: _label(tr, k),
                    selected: current == k,
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (k == StatsPeriodKind.custom) {
                        await pickCustomStatsPeriod(context, ref);
                        return;
                      }
                      ref.read(statsPeriodProvider.notifier).setKind(k);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _go(ExportFormat format) async {
    if (_busy) return;
    if (format == ExportFormat.excel &&
        !await requirePro(context, ref, ProGate.excel)) {
      return;
    }
    if (!mounted) return;
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

class _PeriodDropdownButton extends StatelessWidget {
  const _PeriodDropdownButton({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

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

class _PeriodSheetTile extends StatelessWidget {
  const _PeriodSheetTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
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
                  color: context.primaryText,
                ),
              ),
            ),
            if (selected)
              const Icon(LucideIcons.check, size: 18, color: AppColors.ink),
          ],
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
