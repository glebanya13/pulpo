import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/l10n/tr.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Solid lime pill — rocket + PRO (same mark as cloud backup rows).
class ProBadge extends StatelessWidget {
  const ProBadge({
    super.key,
    this.dense = false,
    this.showLock = false,
    this.onAccent = false,
  });

  final bool dense;

  /// Optional lock glyph before the label (rare; prefer plain PRO).
  final bool showLock;

  /// Use on lime / accent surfaces (dark plate, lime label).
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    final bg = onAccent ? AppColors.ink : AppColors.lime;
    final fg = onAccent ? AppColors.lime : AppColors.ink;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(dense ? 8 : 9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.rocket, size: dense ? 10 : 12, color: fg),
          SizedBox(width: dense ? 4 : 5),
          if (showLock) ...[
            Icon(LucideIcons.lock, size: dense ? 9 : 11, color: fg),
            SizedBox(width: dense ? 3 : 4),
          ],
          Text(
            Tr.of(context).proBadge,
            style: TextStyle(
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1,
              color: fg,
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

/// Compact mark for chrome (tabs / icon overlays). Full [ProBadge] for lists.
class ProChromeMark extends StatelessWidget {
  const ProChromeMark({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) => ProRocketDot(size: size);
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
