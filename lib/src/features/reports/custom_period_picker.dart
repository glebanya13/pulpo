import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import 'stats_period.dart';

Future<void> pickCustomStatsPeriod(
  BuildContext context,
  WidgetRef ref,
) async {
  final range = ref.read(statsPeriodProvider);
  var start = range.kind == StatsPeriodKind.custom
      ? range.start
      : DateTime(DateTime.now().year, DateTime.now().month, 1);
  var end = range.kind == StatsPeriodKind.custom
      ? range.end.subtract(const Duration(days: 1))
      : DateTime.now();

  final tr = Tr.of(context);
  final picked = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text(tr.pickDateRange),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(tr.dateFrom),
              subtitle: Text(
                MaterialLocalizations.of(ctx).formatMediumDate(start),
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: start,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setSt(() => start = d);
              },
            ),
            ListTile(
              title: Text(tr.dateTo),
              subtitle: Text(
                MaterialLocalizations.of(ctx).formatMediumDate(end),
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: end,
                  firstDate: start,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setSt(() => end = d);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr.ok),
          ),
        ],
      ),
    ),
  );
  if (picked != true) return;
  if (end.isBefore(start)) {
    final tmp = start;
    start = end;
    end = tmp;
  }
  ref.read(statsPeriodProvider.notifier).setCustom(
        start,
        DateTime(end.year, end.month, end.day + 1),
      );
}
