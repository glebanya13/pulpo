import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/theme/app_colors.dart';

/// AI assistant avatar — same lime accent as the “Say expense” action.
class AiAssistantMark extends StatelessWidget {
  const AiAssistantMark({
    super.key,
    required this.size,
    this.iconSize,
  });

  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final icon = iconSize ?? size * 0.46;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lime,
        boxShadow: [
          BoxShadow(
            color: AppColors.lime.withValues(alpha: 0.35),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.sparkles,
        size: icon,
        color: AppColors.ink,
      ),
    );
  }
}
