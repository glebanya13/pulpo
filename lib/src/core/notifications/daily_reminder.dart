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
const _kChannelId = 'pulpo_daily_reminder_v5';

final _plugin = FlutterLocalNotificationsPlugin();
var _initialized = false;

enum ReminderSyncResult {
  /// Scheduled or intentionally cancelled (reminder off / onboarding).
  ok,

  /// Reminder was on but OS permission is missing — keep the setting; UI
  /// can prompt when the user toggles. Do not silently turn the toggle off
  /// on cold start (that permanently kills reminders after a flaky check).
  noPermission,
}

Future<void> initDailyReminder() async {
  if (_initialized || kIsWeb) return;
  tzdata.initializeTimeZones();
  await _configureLocalTimezone();

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

Future<void> _configureLocalTimezone() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    final id = info.identifier.trim();
    if (_trySetLocation(id)) return;

    // Common IANA renames / platform quirks.
    const aliases = <String, String>{
      'Europe/Kyiv': 'Europe/Kiev',
      'Asia/Calcutta': 'Asia/Kolkata',
      'Asia/Saigon': 'Asia/Ho_Chi_Minh',
    };
    final mapped = aliases[id];
    if (mapped != null && _trySetLocation(mapped)) return;

    debugPrint('daily reminder tz unknown: $id — using UTC offset fallback');
  } catch (e, st) {
    debugPrint('daily reminder tz: $e\n$st');
  }
  _setLocationFromDeviceOffset();
}

bool _trySetLocation(String id) {
  try {
    tz.setLocalLocation(tz.getLocation(id));
    return true;
  } catch (_) {
    return false;
  }
}

/// Last-resort: keep wall-clock times correct when IANA id is missing.
void _setLocationFromDeviceOffset() {
  final offset = DateTime.now().timeZoneOffset;
  final hours = offset.inHours;
  // Etc/GMT signs are inverted vs usual UTC offsets.
  final name = hours == 0
      ? 'Etc/UTC'
      : (hours > 0 ? 'Etc/GMT-$hours' : 'Etc/GMT+${-hours}');
  if (!_trySetLocation(name)) {
    tz.setLocalLocation(tz.UTC);
  }
}

Future<bool> _iosNotificationsAllowed({required bool request}) async {
  final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  if (ios == null) return false;
  try {
    final existing = await ios.checkPermissions();
    if (existing != null &&
        (existing.isEnabled || existing.isProvisionalEnabled)) {
      return true;
    }
  } catch (e, st) {
    debugPrint('daily reminder checkPermissions: $e\n$st');
  }
  if (!request) return false;
  return await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ??
      false;
}

Future<bool> _macNotificationsAllowed({required bool request}) async {
  final mac = _plugin.resolvePlatformSpecificImplementation<
      MacOSFlutterLocalNotificationsPlugin>();
  if (mac == null) return false;
  try {
    final existing = await mac.checkPermissions();
    if (existing != null &&
        (existing.isEnabled || existing.isProvisionalEnabled)) {
      return true;
    }
  } catch (e, st) {
    debugPrint('daily reminder checkPermissions: $e\n$st');
  }
  if (!request) return false;
  return await mac.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ??
      false;
}

/// Read-only permission check — never prompts. Used by background sync.
Future<bool> hasReminderPermission() async {
  if (kIsWeb) return false;
  await initDailyReminder();
  if (Platform.isIOS) return _iosNotificationsAllowed(request: false);
  if (Platform.isMacOS) return _macNotificationsAllowed(request: false);
  if (Platform.isAndroid) {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }
  return true;
}

/// Prompts when needed. Call only from a user gesture (toggle / time pick).
Future<bool> requestReminderPermission() async {
  if (kIsWeb) return false;
  await initDailyReminder();
  if (Platform.isIOS) return _iosNotificationsAllowed(request: true);
  if (Platform.isMacOS) return _macNotificationsAllowed(request: true);
  if (Platform.isAndroid) {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notif = await android?.requestNotificationsPermission() ?? true;
    if (!notif) return false;
    try {
      await android?.requestExactAlarmsPermission();
    } catch (e, st) {
      debugPrint('exact alarm permission: $e\n$st');
    }
    return true;
  }
  return true;
}

Future<AndroidScheduleMode> _androidScheduleMode() async {
  if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  try {
    final canExact = await android?.canScheduleExactNotifications();
    if (canExact == true) return AndroidScheduleMode.exactAllowWhileIdle;
  } catch (e, st) {
    debugPrint('canScheduleExactNotifications: $e\n$st');
  }
  return AndroidScheduleMode.inexactAllowWhileIdle;
}

NotificationDetails _reminderDetails() {
  return const NotificationDetails(
    android: AndroidNotificationDetails(
      _kChannelId,
      'Monedero',
      channelDescription: 'Daily reminder to log transactions',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_pulpo',
      // Colorful launcher mark — status bar uses white-alpha [icon] above.
      largeIcon: DrawableResourceAndroidBitmap('ic_notification_pulpo'),
      color: Color(0xFFCDFF3A),
      colorized: false,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}

/// Schedules (or cancels) the daily reminder. Returns [ReminderSyncResult.noPermission]
/// when the toggle is on but the OS blocked notifications.
Future<ReminderSyncResult> syncDailyReminder(SettingsState settings) async {
  if (kIsWeb) return ReminderSyncResult.ok;
  await initDailyReminder();
  if (!settings.onboardingDone || !settings.dailyReminderEnabled) {
    await _plugin.cancel(id: _kReminderId);
    return ReminderSyncResult.ok;
  }
  // Check only — never prompt from cold start / settings listen.
  final allowed = await hasReminderPermission();
  if (!allowed) {
    await _plugin.cancel(id: _kReminderId);
    return ReminderSyncResult.noPermission;
  }

  final tr = Tr.fromLang(settings.locale);
  final when = _nextAt(settings.dailyReminderHour, settings.dailyReminderMinute);
  final details = _reminderDetails();
  final preferred = await _androidScheduleMode();

  // Reschedule cleanly — avoids stale one-shots after OS/timezone changes.
  await _plugin.cancel(id: _kReminderId);

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
    await schedule(preferred);
  } catch (e, st) {
    debugPrint('daily reminder $preferred: $e\n$st');
    for (final mode in [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
      AndroidScheduleMode.inexact,
    ]) {
      if (mode == preferred) continue;
      try {
        await schedule(mode);
        return ReminderSyncResult.ok;
      } catch (e2, st2) {
        debugPrint('daily reminder $mode: $e2\n$st2');
      }
    }
  }
  return ReminderSyncResult.ok;
}

tz.TZDateTime _nextAt(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (!at.isAfter(now)) {
    at = at.add(const Duration(days: 1));
  }
  return at;
}
