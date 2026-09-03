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

class LanguagePickerScreen extends ConsumerWidget {
  const LanguagePickerScreen({super.key});

    static const _langs = [
    ('es', 'Español', '🇪🇸'),
    ('uk', 'Українська', '🇺🇦'),
    ('ru', 'Русский', '🇷🇺'),
    ('en', 'English', '🇬🇧'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsControllerProvider).locale;
    final tr = Tr.of(context);

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(first: tr.language, onBack: () => context.pop()),
        children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: context.surface,
                child: Column(
                  children: [
                    for (var i = 0; i < _langs.length; i++)
                      Pressable(
                        onTap: () async {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .setLocale(_langs[i].$1);
                          if (context.mounted) context.pop();
                        },
                        scale: 0.99,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: current == _langs[i].$1
                                ? AppColors.lime.withValues(alpha: 0.08)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: current == _langs[i].$1
                                    ? AppColors.lime
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(_langs[i].$3,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(_langs[i].$2,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: context.primaryText)),
                              ),
                              if (current == _langs[i].$1)
                                Icon(LucideIcons.check,
                                    color: context.accent, size: 20),
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
