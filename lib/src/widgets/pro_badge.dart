import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Compact lime pill that marks a Pro-only control (buttons, tabs, sheets).
class ProBadge extends StatelessWidget {
  const ProBadge({
    super.key,
    this.dense = false,
    this.showLock = true,
  });

  final bool dense;
  final bool showLock;

  @override
  Widget build(BuildContext context) {
    final accent =
        context.isDark ? AppColors.lime : AppColors.limeAccent;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLock) ...[
            Icon(LucideIcons.lock, size: dense ? 10 : 12, color: accent),
            SizedBox(width: dense ? 3 : 4),
          ],
          Text(
            'PRO',
            style: TextStyle(
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              height: 1,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rocket badge overlaid on a leading icon — readable without tapping.
class ProIconMark extends StatelessWidget {
  const ProIconMark({
    super.key,
    required this.child,
    this.size = 36,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badge = (size * 0.42).clamp(14.0, 18.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: -3,
            top: -3,
            child: ProRocketDot(size: badge),
          ),
        ],
      ),
    );
  }
}

/// Standalone rocket chip for list trailing / compact marks.
class ProRocketDot extends StatelessWidget {
  const ProRocketDot({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.isDark ? AppColors.ink : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lime.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        LucideIcons.rocket,
        size: size * 0.55,
        color: AppColors.ink,
      ),
    );
  }
}

/// Dimmed label color for Pro-locked rows.
Color proLockedTextColor(BuildContext context, {bool danger = false}) {
  if (danger) return const Color(0xFFE53E3E).withValues(alpha: 0.55);
  return context.primaryText.withValues(alpha: context.isDark ? 0.42 : 0.38);
}

Color proLockedMutedColor(BuildContext context) =>
    context.mutedText.withValues(alpha: 0.55);
