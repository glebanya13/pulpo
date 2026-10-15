part of 'paywall_screen.dart';

class _PaywallPlansSkeleton extends StatelessWidget {
  const _PaywallPlansSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _PaywallPlanSkeleton(hasBadge: i > 0),
        ],
      ],
    );
  }
}

class _PaywallPlanSkeleton extends StatelessWidget {
  const _PaywallPlanSkeleton({this.hasBadge = false});

  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    final fill = context.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF0F0F0);
    return Container(
      height: hasBadge ? 78 : 68,
      padding: EdgeInsets.fromLTRB(12, hasBadge ? 16 : 12, 12, 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 12,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 9,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 14,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
class _PaywallPlanCard extends StatelessWidget {
  const _PaywallPlanCard({
    required this.title,
    required this.price,
    required this.allFeaturesLabel,
    required this.onTap,
    this.trialLabel,
    this.badge,
    this.comparePrice,
    this.selected = false,
    this.busy = false,
  });

  final String title;
  final String price;
  final String allFeaturesLabel;
  final String? trialLabel;
  final String? badge;
  final String? comparePrice;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    // На light neon-lime текст на lime-фоне не читается — белая карточка + тёмная рамка.
    final cardFill = selected
        ? (isDark
            ? AppColors.lime.withValues(alpha: 0.18)
            : context.surface)
        : context.surface;
    final cardBorder = selected
        ? (isDark ? AppColors.lime : AppColors.limeAccent)
        : context.divider;
    final secondaryText =
        isDark ? context.mutedText : AppColors.textSecondary;
    final trialColor = selected
        ? (isDark ? AppColors.lime : context.primaryText)
        : context.primaryText;

    return Pressable(
      enabled: !busy,
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.fromLTRB(12, badge != null ? 16 : 10, 12, 10),
        decoration: BoxDecoration(
          color: cardFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (badge != null)
              Positioned(
                top: -24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? AppColors.lime : AppColors.limeAccent)
                          : AppColors.ink,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: selected ? AppColors.ink : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.zap,
                            size: 11,
                            color: secondaryText,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              allFeaturesLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (trialLabel != null && trialLabel!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          trialLabel!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: trialColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: context.primaryText,
                      ),
                    ),
                    if (comparePrice != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        comparePrice!,
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: isDark
                              ? context.faintText
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
