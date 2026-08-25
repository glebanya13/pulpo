import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/theme/app_colors.dart';
import 'pro_badge.dart';

/// AI assistant mark — violet circle + white robot.
class AiAssistantMark extends StatelessWidget {
  const AiAssistantMark({
    super.key,
    required this.size,
    this.iconSize,
    this.needsUpgrade = false,
  });

  final double size;
  final double? iconSize;

  /// Free quota spent — show Pro chrome on the violet AI mark.
  final bool needsUpgrade;

  @override
  Widget build(BuildContext context) {
    final icon = iconSize ?? size * 0.46;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B7CFF),
                  AppColors.violet,
                  Color(0xFFC4B5FD),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.4),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.bot,
              size: icon,
              color: Colors.white,
            ),
          ),
          if (needsUpgrade)
            Positioned(
              right: -3,
              top: -3,
              child: ProChromeMark(size: (size * 0.42).clamp(12.0, 16.0)),
            ),
        ],
      ),
    );
  }
}
