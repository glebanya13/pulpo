import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class ThemePickerScreen extends ConsumerWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsControllerProvider).themeMode;
    final tr = Tr.of(context);
    final options = [
      ('light', tr.themeLight, LucideIcons.sun),
      ('dark', tr.themeDark, LucideIcons.moon),
      ('system', tr.themeSystem, LucideIcons.smartphone),
    ];

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(first: tr.theme, onBack: () => context.pop()),
        children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: context.surface,
                child: Column(
                  children: [
                    for (var i = 0; i < options.length; i++)
                      Pressable(
                        onTap: () async {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .setTheme(options[i].$1);
                          if (context.mounted) context.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: current == options[i].$1
                                ? AppColors.lime.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: current == options[i].$1
                                    ? AppColors.lime
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(options[i].$3,
                                  size: 20, color: context.primaryText),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  options[i].$2,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.primaryText,
                                  ),
                                ),
                              ),
                              if (current == options[i].$1)
                                const Icon(LucideIcons.check,
                                    color: AppColors.limeAccent, size: 20),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
