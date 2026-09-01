import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/ai/assistant_energy.dart';
import '../core/pro/pro_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/liquid_glass.dart';
import 'ai_assistant_mark.dart';
import 'pressable.dart';

/// Pill bottom nav: home · txs · plus (bright FAB) · reports · chat (quiet).
class BudgetBottomNav extends StatelessWidget {
  const BudgetBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
    required this.onChatTap,
  });

  /// Shell tab index: 0 home, 1 transactions, 2 reports.
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.symmetric(horizontal: 20),
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: LucideIcons.layoutDashboard,
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: LucideIcons.arrowLeftRight,
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _Fab(
              icon: LucideIcons.plus,
              size: 52,
              iconSize: 24,
              onTap: onAddTap,
            ),
            _NavItem(
              icon: LucideIcons.pieChart,
              active: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _AiNavItem(onTap: onChatTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final idle = context.isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.ink.withValues(alpha: 0.42);
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active ? AppColors.lime : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? AppColors.ink : idle,
        ),
      ),
    );
  }
}

class _AiNavItem extends ConsumerWidget {
  const _AiNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proControllerProvider).isPro;
    final hasEnergy = ref.watch(assistantEnergyProvider).hasEnergy;
    final needsUpgrade = !isPro && !hasEnergy;
    return Pressable(
      onTap: onTap,
      child: AiAssistantMark(
        size: 38,
        iconSize: 17,
        needsUpgrade: needsUpgrade,
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.lime,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.lime.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.ink, size: iconSize),
      ),
    );
  }
}
