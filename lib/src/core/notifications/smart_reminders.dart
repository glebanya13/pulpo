import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/db/app_database.dart' as db;
import '../../data/repositories/settings_service.dart';
import '../l10n/tr.dart';
import 'daily_reminder.dart';

const _kSmartChannelId = 'pulpo_smart_reminders';
const _kSmartIdsKey = 'smart_reminder_ids';
const _kDebtBase = 3100;
const _kSubBase = 4100;
const _kGoalBase = 5100;

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> syncSmartReminders({
  required SharedPreferences prefs,
  required SettingsState settings,
  required bool isPro,
  required List<db.Debt> debts,
  required List<db.Subscription> subscriptions,
  required List<db.Goal> goals,
}) async {
  if (kIsWeb) return;
  await initDailyReminder();
  await _cancelTracked(prefs);

  if (!isPro || !settings.smartRemindersEnabled || !settings.onboardingDone) {
    return;
  }

  final allowed = await requestReminderPermission();
  if (!allowed) return;

  final tr = Tr.fromLang(settings.locale);
  final ids = <int>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final d in debts) {
    final due = d.dueDate;
    if (due == null) continue;
    if (d.status != 0) continue;
    if (d.paidAmount + 0.005 >= d.amount) continue;
    final day = DateTime(due.year, due.month, due.day);
    if (day.isBefore(today)) continue;
    final when = _atTen(day);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
    final id = _kDebtBase + d.id;
    await _schedule(
      id: id,
      title: tr.smartDebtTitle,
      body: tr.smartDebtBody(d.counterparty),
      when: when,
    );
    ids.add(id);
  }

  for (final s in subscriptions) {
    if (s.isPaused) continue;
    final next = s.nextPayment;
    final remindOn = DateTime(next.year, next.month, next.day)
        .subtract(const Duration(days: 1));
    final day = remindOn.isBefore(today) ? DateTime(next.year, next.month, next.day) : remindOn;
    if (day.isBefore(today)) continue;
    final when = _atTen(day);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
    final id = _kSubBase + s.id;
    await _schedule(
      id: id,
      title: tr.smartSubTitle,
      body: tr.smartSubBody(s.name),
      when: when,
    );
    ids.add(id);
  }

  for (final g in goals) {
    if (g.isCompleted) continue;
    final target = g.targetDate;
    if (target == null) continue;
    final day = DateTime(target.year, target.month, target.day);
    if (day.isBefore(today)) continue;
    final when = _atTen(day);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
    final id = _kGoalBase + g.id;
    await _schedule(
      id: id,
      title: tr.smartGoalTitle,
      body: tr.smartGoalBody(g.name),
      when: when,
    );
    ids.add(id);
  }

  await prefs.setStringList(_kSmartIdsKey, [for (final id in ids) '$id']);
}

Future<void> _cancelTracked(SharedPreferences prefs) async {
  final prev = prefs.getStringList(_kSmartIdsKey) ?? const [];
  for (final raw in prev) {
    final id = int.tryParse(raw);
    if (id == null) continue;
    await _plugin.cancel(id: id);
  }
  await prefs.remove(_kSmartIdsKey);
}

tz.TZDateTime _atTen(DateTime day) {
  return tz.TZDateTime(tz.local, day.year, day.month, day.day, 10);
}

Future<void> _schedule({
  required int id,
  required String title,
  required String body,
  required tz.TZDateTime when,
}) async {
  if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kSmartChannelId,
        'Pulpo Pro',
        channelDescription: 'Payment, subscription and goal reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e, st) {
      debugPrint('smart reminder: $e\n$st');
    }
  }
}
