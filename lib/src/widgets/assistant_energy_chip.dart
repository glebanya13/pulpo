import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/ai/assistant_energy.dart';
import '../core/pro/pro_controller.dart';
import '../core/pro/pro_guard.dart';
import '../core/pro/pro_limits.dart';
import '../core/theme/app_theme.dart';
import 'pressable.dart';

/// Compact ⚡N capsule for free users; hidden for Pro.
class AssistantEnergyChip extends ConsumerWidget {
  const AssistantEnergyChip({super.key, this.onEmpty});

  /// Called when the user taps with 0 energy (defaults to paywall).
  final VoidCallback? onEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(proControllerProvider).isPro) {
      return const SizedBox.shrink();
    }

    final energy = ref.watch(assistantEnergyProvider);
    final units = energy.units;
    final empty = !energy.hasEnergy;
    final bolt = empty
        ? context.mutedText
        : const Color(0xFF5B9DFF);

    return Pressable(
      onTap: () async {
        if (empty) {
          if (onEmpty != null) {
            onEmpty!();
          } else {
            await openPaywall(context, ProGate.ai);
          }
          return;
        }
        await openPaywall(context, ProGate.ai);
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.zap, size: 14, color: bolt),
            const SizedBox(width: 4),
            Text(
              '$units',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: empty ? context.mutedText : context.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
