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
    ('ru', 'Русский', '🇷🇺'),
    ('en', 'English', '🇬🇧'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsControllerProvider).locale;
    final tr = Tr.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(first: tr.language, onBack: () => context.pop()),
            const SizedBox(height: 20),
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
      ),
    );
  }
}
