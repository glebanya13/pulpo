import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StatsPeriodKind {
  thisMonth,
  lastMonth,
  months3,
  months6,
  thisYear,
  lastYear,
  custom,
}

class StatsRange {
  const StatsRange({
    required this.kind,
    required this.start,
    required this.end,
  });

  final StatsPeriodKind kind;
  final DateTime start;
  final DateTime end;
}

StatsRange rangeFor(StatsPeriodKind kind, {DateTime? customStart, DateTime? customEnd}) {
  final now = DateTime.now();
  final todayEnd = DateTime(now.year, now.month, now.day + 1);
  switch (kind) {
    case StatsPeriodKind.thisMonth:
      return StatsRange(
        kind: kind,
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 1),
      );
    case StatsPeriodKind.lastMonth:
      return StatsRange(
        kind: kind,
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 1),
      );
    case StatsPeriodKind.months3:
      return StatsRange(
        kind: kind,
        start: DateTime(now.year, now.month - 2, 1),
        end: todayEnd,
      );
    case StatsPeriodKind.months6:
      return StatsRange(
        kind: kind,
        start: DateTime(now.year, now.month - 5, 1),
        end: todayEnd,
      );
    case StatsPeriodKind.thisYear:
      return StatsRange(
        kind: kind,
        start: DateTime(now.year, 1, 1),
        end: todayEnd,
      );
    case StatsPeriodKind.lastYear:
      return StatsRange(
        kind: kind,
        start: DateTime(now.year - 1, 1, 1),
        end: DateTime(now.year, 1, 1),
      );
    case StatsPeriodKind.custom:
      return StatsRange(
        kind: kind,
        start: customStart ?? DateTime(now.year, now.month, 1),
        end: customEnd ?? todayEnd,
      );
  }
}

class StatsPeriodController extends Notifier<StatsRange> {
  @override
  StatsRange build() => rangeFor(StatsPeriodKind.thisMonth);

  void setKind(StatsPeriodKind kind) => state = rangeFor(kind);

  void setCustom(DateTime start, DateTime end) {
    state = StatsRange(kind: StatsPeriodKind.custom, start: start, end: end);
  }
}

final statsPeriodProvider =
    NotifierProvider<StatsPeriodController, StatsRange>(StatsPeriodController.new);
