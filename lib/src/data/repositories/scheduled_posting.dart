import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'recurring_repository.dart';

/// Сдвигает дату по частоте правила (daily|weekly|monthly|yearly).
DateTime advanceSchedule(DateTime from, String frequency, [int interval = 1]) {
  final step = interval < 1 ? 1 : interval;
  switch (frequency) {
    case 'daily':
      return from.add(Duration(days: step));
    case 'weekly':
      return from.add(Duration(days: 7 * step));
    case 'yearly':
      return addCalendarMonths(from, 12 * step);
    case 'monthly':
    default:
      return addCalendarMonths(from, step);
  }
}

DateTime addCalendarMonths(DateTime from, int months) {
  var year = from.year;
  var month = from.month + months;
  while (month > 12) {
    month -= 12;
    year++;
  }
  while (month < 1) {
    month += 12;
    year--;
  }
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = from.day > lastDay ? lastDay : from.day;
  return DateTime(
    year,
    month,
    day,
    from.hour,
    from.minute,
    from.second,
    from.millisecond,
  );
}

/// Создаёт просроченные операции по правилам и подпискам.
Future<int> postDueScheduledItems(
  AppDatabase db, {
  DateTime? now,
}) async {
  final at = now ?? DateTime.now();
  var posted = 0;
  posted += await _postRecurring(db, at);
  posted += await _postSubscriptions(db, at);
  return posted;
}

Future<int> _postRecurring(AppDatabase db, DateTime now) async {
  final rules = await (db.select(db.recurringRules)
        ..where((r) => r.isPaused.equals(false)))
      .get();
  var posted = 0;
  for (final rule in rules) {
    var next = rule.nextRunAt;
    var runs = 0;
    while (!next.isAfter(now) && runs < 24) {
      if (rule.endAt != null && next.isAfter(rule.endAt!)) break;
      final t = RecurringTemplate.fromJson(rule.templateJson);
      if (t.accountId > 0) {
        await db.into(db.transactions).insert(
              TransactionsCompanion.insert(
                accountId: t.accountId,
                categoryId: Value(t.categoryId),
                amount: t.amount,
                currency: t.currency,
                type: t.type.index,
                date: next,
                note: Value(t.name.isEmpty ? null : t.name),
              ),
            );
        posted++;
      }
      next = advanceSchedule(next, rule.frequency, rule.interval);
      runs++;
    }
    if (next != rule.nextRunAt) {
      await (db.update(db.recurringRules)..where((r) => r.id.equals(rule.id)))
          .write(RecurringRulesCompanion(nextRunAt: Value(next)));
    }
  }
  return posted;
}

Future<int> _postSubscriptions(AppDatabase db, DateTime now) async {
  final subs = await (db.select(db.subscriptions)
        ..where((s) => s.isPaused.equals(false)))
      .get();
  var posted = 0;
  for (final sub in subs) {
    if (sub.accountId == null) continue;
    var next = sub.nextPayment;
    var runs = 0;
    while (!next.isAfter(now) && runs < 24) {
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: sub.accountId!,
              categoryId: Value(sub.categoryId),
              amount: sub.amount,
              currency: sub.currency,
              type: TxType.expense.index,
              date: next,
              note: Value(sub.name),
            ),
          );
      posted++;
      next = sub.cycle == 'yearly'
          ? addCalendarMonths(next, 12)
          : addCalendarMonths(next, 1);
      runs++;
    }
    if (next != sub.nextPayment) {
      await (db.update(db.subscriptions)..where((s) => s.id.equals(sub.id)))
          .write(SubscriptionsCompanion(nextPayment: Value(next)));
    }
  }
  return posted;
}
