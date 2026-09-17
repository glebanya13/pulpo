part of 'paywall_screen.dart';

class _PaywallPlansSkeleton extends StatelessWidget {
  const _PaywallPlansSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 10),
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
      height: hasBadge ? 98 : 88,
      padding: EdgeInsets.fromLTRB(16, hasBadge ? 22 : 16, 16, 16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 88,
                  height: 14,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 120,
                  height: 10,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 18,
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
        padding: EdgeInsets.fromLTRB(16, badge != null ? 22 : 16, 16, 16),
        decoration: BoxDecoration(
          color: cardFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (badge != null)
              Positioned(
                top: -30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? AppColors.lime : AppColors.limeAccent)
                          : AppColors.ink,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.zap,
                            size: 12,
                            color: secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            allFeaturesLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                      if (trialLabel != null && trialLabel!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          trialLabel!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: trialColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                      ),
                    ),
                    if (comparePrice != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        comparePrice!,
                        style: TextStyle(
                          fontSize: 12,
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
