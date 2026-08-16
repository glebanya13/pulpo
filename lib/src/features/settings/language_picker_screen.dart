import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RoundIconButton(
                    icon: LucideIcons.arrowLeft, onTap: () => context.pop()),
                Text(tr.language,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    for (var i = 0; i < _langs.length; i++) ...[
                      InkWell(
                        onTap: () async {
                          await ref
                              .read(settingsServiceProvider)
                              .setLocale(_langs[i].$1);
                          ref.invalidate(settingsControllerProvider);
                          if (context.mounted) context.pop();
                        },
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
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ),
                              if (current == _langs[i].$1)
                                const Icon(LucideIcons.check,
                                    color: AppColors.limeAccent, size: 20),
                            ],
                          ),
                        ),
                      ),
                      if (i != _langs.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(left: 66, right: 16),
                          child:
                              Divider(height: 1, color: AppColors.divider),
                        ),
                    ],
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
