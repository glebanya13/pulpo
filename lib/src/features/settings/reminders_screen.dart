import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';
import 'reminder_settings.dart';

/// Daily reminders (free) + smart event reminders (Pro).
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final isPro = ref.watch(proControllerProvider).isPro;
    final time = formatReminderTime(
      settings.dailyReminderHour,
      settings.dailyReminderMinute,
    );

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(first: tr.dailyReminderCta, onBack: () => context.pop()),
        headerGap: 16,
        children: [
            Text(
              tr.remindersPageHint,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: context.mutedText,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr.dailyReminderSection,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.mutedText,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.bell,
                          size: 20,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.dailyReminder,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.primaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              settings.dailyReminderEnabled
                                  ? tr.dailyReminderAt(time)
                                  : tr.dailyReminderOffHint,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: context.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: settings.dailyReminderEnabled,
                        onChanged: (v) =>
                            toggleDailyReminder(context, ref, tr, v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Pressable(
                    onTap: () => pickReminderTime(context, ref, settings),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: context.scaffoldBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 18,
                            color: context.primaryText,
                          ),
                          const SizedBox(width: 10),
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
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              tr.smartReminders,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.mutedText,
              ),
            ),
            const SizedBox(height: 10),
            _SmartRemindersCard(
              enabled: settings.smartRemindersEnabled,
              isPro: isPro,
              onChanged: (v) => toggleSmartReminders(context, ref, tr, v),
            ),
          ],
        ),
    );
  }
}

class _SmartRemindersCard extends StatelessWidget {
  const _SmartRemindersCard({
    required this.enabled,
    required this.isPro,
    required this.onChanged,
  });

  final bool enabled;
  final bool isPro;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.limeDark,
            AppColors.lime,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lime.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tr.smartReminders,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const ProBadge(dense: true, onAccent: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr.smartRemindersHint,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled && isPro,
                activeThumbColor: AppColors.ink,
                activeTrackColor: AppColors.ink.withValues(alpha: 0.35),
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr.smartRemindersDesc,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColors.ink.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
