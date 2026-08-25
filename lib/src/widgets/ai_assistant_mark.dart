import 'package:flutter/material.dart';

import 'pro_badge.dart';

/// Brand AI assistant mark (lime star + violet bot art).
class AiAssistantMark extends StatelessWidget {
  const AiAssistantMark({
    super.key,
    required this.size,
    this.iconSize,
    this.needsUpgrade = false,
  });

  final double size;

  /// Unused — kept for call-site compatibility with the old Lucide mark.
  final double? iconSize;

  /// Free quota spent — show Pro chrome on the AI mark.
  final bool needsUpgrade;

  static const assetPath = 'assets/ai_assistant.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.22),
            child: Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
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
