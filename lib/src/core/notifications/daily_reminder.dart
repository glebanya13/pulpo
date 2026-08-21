import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/repositories/settings_service.dart';
import '../l10n/tr.dart';

const _kReminderId = 2100;
const _kChannelId = 'pulpo_daily_reminder_v2';

final _plugin = FlutterLocalNotificationsPlugin();
var _initialized = false;

Future<void> initDailyReminder() async {
  if (_initialized || kIsWeb) return;
  tzdata.initializeTimeZones();
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } catch (e, st) {
    debugPrint('daily reminder tz: $e\n$st');
  }

  const android = AndroidInitializationSettings('@drawable/ic_stat_pulpo');
  const darwin = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    ),
  );
  _initialized = true;
}

Future<bool> requestReminderPermission() async {
  if (kIsWeb) return false;
  if (Platform.isIOS || Platform.isMacOS) {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    final ok = await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        await mac?.requestPermissions(alert: true, badge: true, sound: true);
    return ok ?? false;
  }
  if (Platform.isAndroid) {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }
  return true;
}

Future<void> syncDailyReminder(SettingsState settings) async {
  if (kIsWeb) return;
  await initDailyReminder();
  if (!settings.onboardingDone || !settings.dailyReminderEnabled) {
    await _plugin.cancel(id: _kReminderId);
    return;
  }
  final allowed = await requestReminderPermission();
  if (!allowed) {
    await _plugin.cancel(id: _kReminderId);
    return;
  }

  final tr = Tr.fromLang(settings.locale);
  final when = _nextAt(settings.dailyReminderHour, settings.dailyReminderMinute);
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _kChannelId,
      'Pulpo',
      channelDescription: 'Daily reminder to log transactions',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_pulpo',
      largeIcon: DrawableResourceAndroidBitmap('ic_notification_pulpo'),
      color: Color(0xFFCDFF3A),
      colorized: false,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  Future<void> schedule(AndroidScheduleMode mode) {
    return _plugin.zonedSchedule(
      id: _kReminderId,
      title: tr.dailyReminderTitle,
      body: tr.dailyReminderBody,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  try {
    await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
  } catch (e, st) {
    debugPrint('daily reminder schedule: $e\n$st');
    try {
      await schedule(AndroidScheduleMode.inexact);
    } catch (e2, st2) {
      debugPrint('daily reminder fallback: $e2\n$st2');
    }
  }
}

tz.TZDateTime _nextAt(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (!at.isAfter(now)) {
    at = at.add(const Duration(days: 1));
  }
  return at;
}
