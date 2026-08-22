import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/theme/app_colors.dart';

/// AI assistant mark — violet / bot, not lime (Pro uses lime + rocket).
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
    );
  }
}
