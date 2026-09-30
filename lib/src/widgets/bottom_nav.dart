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

/// Pill bottom nav + external + FAB (home · reports · management · chat | +).
class BudgetBottomNav extends StatelessWidget {
  const BudgetBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
    required this.onManagementTap,
    required this.onChatTap,
  });

  /// Shell tab index: 0 home, 1 reports, 2 management.
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;
  final VoidCallback onManagementTap;
  final VoidCallback onChatTap;

  static const double _fabSize = 56;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: LiquidGlass(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Row(
                children: [
                  _NavItem(
                    icon: LucideIcons.house,
                    active: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: LucideIcons.pieChart,
                    active: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _NavItem(
                    icon: LucideIcons.layoutGrid,
                    active: currentIndex == 2,
                    onTap: onManagementTap,
                  ),
                  _AiNavItem(onTap: onChatTap),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _Fab(
            icon: LucideIcons.plus,
            size: _fabSize,
            iconSize: 26,
            onTap: onAddTap,
          ),
        ],
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
    final activeBg = context.isDark ? Colors.white : AppColors.ink;
    final activeFg = context.isDark ? AppColors.ink : Colors.white;
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: active,
          child: SizedBox(
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: active ? activeBg : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: active ? activeFg : idle,
                ),
              ),
            ),
          ),
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
    final hasEnergy = ref.watch(
      assistantEnergyProvider.select((e) => e.hasEnergy),
    );
    final needsUpgrade = !isPro && !hasEnergy;
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: AiAssistantMark(
              size: 44,
              iconSize: 18,
              needsUpgrade: needsUpgrade,
            ),
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({
    required this.icon,
    required this.onTap,
    this.size = 56,
    this.iconSize = 26,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8FF6A),
              AppColors.lime,
              AppColors.limeDark,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.lime.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.ink, size: iconSize),
      ),
    );
  }
}
