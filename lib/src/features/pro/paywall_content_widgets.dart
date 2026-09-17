part of 'paywall_screen.dart';

class _PaywallProHero extends StatelessWidget {
  const _PaywallProHero();

  static const _size = 104.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4FF00),
            AppColors.lime,
            Color(0xFFF0FF7A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lime.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        LucideIcons.rocket,
        size: 48,
        color: AppColors.ink,
      ),
    );
  }
}

class _ProFeaturesCard extends StatelessWidget {
  const _ProFeaturesCard({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 12,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    features[i],
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProActiveSection extends ConsumerStatefulWidget {
  const _ProActiveSection({required this.pro});

  final ProState pro;

  @override
  ConsumerState<_ProActiveSection> createState() => _ProActiveSectionState();
}

class _ProActiveSectionState extends ConsumerState<_ProActiveSection> {
  @override
  void initState() {
    super.initState();
    if (widget.pro.subscriptionExpiresAt == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(proControllerProvider.notifier).refresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final pro = ref.watch(proControllerProvider);
    final expiresAt = pro.subscriptionExpiresAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.badgeCheck,
            size: 28,
            color: context.isDark ? AppColors.lime : AppColors.ink,
          ),
          const SizedBox(height: 10),
          Text(
            tr.proActive,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          if (expiresAt != null) ...[
            Text(
              tr.proValidUntil(formatProExpiryDate(context, expiresAt)),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: context.primaryText,
              ),
            ),
            if (pro.daysUntilExpiry != null && pro.daysUntilExpiry! <= 14) ...[
              const SizedBox(height: 6),
              Text(
                tr.proDaysLeft(pro.daysUntilExpiry!),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ] else
            Text(
              tr.proExpiresLoading,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.mutedText,
              ),
            ),
        ],
      ),
    );
  }
}
