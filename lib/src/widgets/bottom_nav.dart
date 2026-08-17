import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Тёмный pill bottom nav: 4 иконки + FAB в центре.
class BudgetBottomNav extends StatelessWidget {
  const BudgetBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    final homeInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        (homeInset * 0.4).clamp(8, 14),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.emphasized,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: context.emphasizedBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
            _Fab(onTap: onFabTap),
            _NavItem(
              icon: LucideIcons.pieChart,
              active: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: LucideIcons.user,
              active: currentIndex == 3,
              onTap: () => onTap(3),
            ),
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
    return InkResponse(
      onTap: onTap,
      radius: 20,
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
          color: active ? AppColors.ink : Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.lime,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.lime.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.ink, size: 22),
      ),
    );
  }
}
