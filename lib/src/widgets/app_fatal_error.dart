import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/l10n/tr.dart';
import '../core/theme/app_colors.dart';
import 'common.dart';

/// User-facing screen when a widget fails to build (release only).
class AppFatalErrorWidget extends StatelessWidget {
  const AppFatalErrorWidget({
    super.key,
    required this.details,
  });

  final FlutterErrorDetails details;

  static String _langCode() {
    final code =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return switch (code) {
      'ru' || 'uk' || 'en' => code,
      _ => 'es',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.fromLang(_langCode());
    if (kDebugMode) {
      debugPrint('Fatal widget error: ${details.exceptionAsString()}');
      if (details.stack != null) {
        debugPrint(details.stack.toString());
      }
    }

    return Material(
      color: AppColors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandLogo(size: 64),
              const SizedBox(height: 28),
              Text(
                tr.errorTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr.errorFatalBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tr.errorFatalHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
