import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/notifications/daily_reminder.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/pressable.dart';

String formatReminderTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

Future<void> openReminderSheet(
  BuildContext context,
  WidgetRef ref,
  Tr tr,
) async {
  await showAppBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsControllerProvider);
          final time = formatReminderTime(
            settings.dailyReminderHour,
            settings.dailyReminderMinute,
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
                  Text(
                    tr.dailyReminderCta,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr.dailyReminder,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.mutedText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.scaffoldBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr.dailyReminder,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.primaryText,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: settings.dailyReminderEnabled,
                          onChanged: (v) =>
                              toggleDailyReminder(context, ref, tr, v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => pickReminderTime(context, ref, settings),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 18,
                              color: context.primaryText,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tr.dailyReminderTime,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.primaryText,
                                ),
                              ),
                            ),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.primaryText,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: context.faintText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> toggleDailyReminder(
  BuildContext context,
  WidgetRef ref,
  Tr tr,
  bool enabled,
) async {
  if (enabled) {
    await initDailyReminder();
    final ok = await requestReminderPermission();
    if (!ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.reminderPermissionDenied)),
        );
      }
      // Keep toggle off — otherwise UI says "on" but nothing is scheduled.
      return;
    }
  }
  await ref.read(settingsControllerProvider.notifier).setDailyReminderEnabled(
        enabled,
      );
}

Future<void> toggleSmartReminders(
  BuildContext context,
  WidgetRef ref,
  Tr tr,
  bool enabled,
) async {
  if (enabled) {
    final ok = await requirePro(context, ref, ProGate.reminders);
    if (!ok) return;
    await initDailyReminder();
    final allowed = await requestReminderPermission();
    if (!allowed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.reminderPermissionDenied)),
        );
      }
      return;
    }
  }
  await ref.read(settingsControllerProvider.notifier).setSmartRemindersEnabled(
        enabled,
      );
}

Future<void> pickReminderTime(
  BuildContext context,
  WidgetRef ref,
  SettingsState settings,
) async {
  final tr = Tr.of(context);
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: settings.dailyReminderHour,
      minute: settings.dailyReminderMinute,
    ),
    builder: (ctx, child) {
      return Theme(
        data: Theme.of(context),
        child: MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    },
  );
  if (picked == null) return;
  await ref.read(settingsControllerProvider.notifier).setDailyReminderTime(
        picked.hour,
        picked.minute,
      );
  if (!settings.dailyReminderEnabled) {
    if (!context.mounted) return;
    await toggleDailyReminder(context, ref, tr, true);
  }
}

class ReminderCtaButton extends StatelessWidget {
  const ReminderCtaButton({
    super.key,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: enabled
                ? const [
                    AppColors.limeDark,
                    AppColors.lime,
                  ]
                : const [
                    Color(0xFF64748B),
                    Color(0xFF475569),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: (enabled ? AppColors.lime : const Color(0xFF475569))
                  .withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (enabled ? AppColors.ink : Colors.white)
                    .withValues(alpha: enabled ? 0.12 : 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                enabled ? LucideIcons.bellRing : LucideIcons.bellOff,
                size: 22,
                color: enabled ? AppColors.ink : Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: enabled ? AppColors.ink : Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: enabled
                          ? AppColors.ink.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.88),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: enabled
                  ? AppColors.ink.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}
