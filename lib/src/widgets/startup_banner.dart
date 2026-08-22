import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_startup.dart';
import '../core/l10n/tr.dart';
import '../core/theme/app_colors.dart';

/// Overlay when Firebase or startup data init failed (offline-capable app).
class StartupBannerHost extends ConsumerWidget {
  const StartupBannerHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);
    final tr = Tr.of(context);
    final messages = <String>[
      if (startup.showFirebaseWarning) tr.firebaseOfflineBanner,
      if (startup.showDataWarning) tr.dataInitFailedBanner,
    ];
    if (messages.isEmpty) return child;

    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Material(
            elevation: 2,
            color: AppColors.ink,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white70, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      messages.join('\n'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
