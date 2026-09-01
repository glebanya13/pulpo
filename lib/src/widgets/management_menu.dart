import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/l10n/tr.dart';
import '../core/pro/pro_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/color_well.dart';
import 'app_bottom_sheet.dart';
import 'pressable.dart';
import 'pro_badge.dart';

typedef ManagementMenuItem = (IconData, String, String, Color, bool);

List<ManagementMenuItem> managementMenuItems(Tr tr) => [
      (LucideIcons.wallet, tr.accounts, '/accounts', const Color(0xFF8BD44A), false),
      (LucideIcons.pieChart, tr.budgets, '/budgets', const Color(0xFFFFB020), false),
      (
        LucideIcons.usersRound,
        tr.sharedBudgetTitle,
        '/shared-budget',
        const Color(0xFF7C6CFF),
        true,
      ),
      (LucideIcons.users, tr.debts, '/debts', const Color(0xFFFF5C5C), false),
      (LucideIcons.tv, tr.subscriptions, '/subscriptions', const Color(0xFF7C6CFF), false),
      (LucideIcons.repeat, tr.recurringOps, '/recurring', const Color(0xFF2EB5FF), false),
      (LucideIcons.target, tr.goals, '/goals', const Color(0xFFCDFF3A), false),
      (LucideIcons.layers, tr.categories, '/categories', const Color(0xFFD4F5E0), false),
    ];

Future<void> showManagementMenu(BuildContext context, WidgetRef ref) async {
  final tr = Tr.of(context);
  final isPro = ref.read(proControllerProvider).isPro;
  final items = managementMenuItems(tr);

  await showAppBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      final bottomInset = MediaQuery.viewPaddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ctx.handleBar,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr.management,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ctx.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: items.length + 1,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: ctx.divider),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Pressable(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/profile');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: _ManagementMenuRow(
                          icon: LucideIcons.user,
                          label: tr.myAccount,
                          color: AppColors.lime,
                          showPro: false,
                        ),
                      ),
                    );
                  }
                  final item = items[i - 1];
                  return Pressable(
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(item.$3);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: _ManagementMenuRow(
                        icon: item.$1,
                        label: item.$2,
                        color: item.$4,
                        showPro: item.$5 && !isPro,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ManagementMenuRow extends StatelessWidget {
  const _ManagementMenuRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.showPro,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool showPro;

  @override
  Widget build(BuildContext context) {
    final iconWell = ColorWellIcon(
      color: color,
      icon: icon,
      size: 28,
      iconSize: 14,
      radius: 8,
    );
    return Row(
      children: [
        if (showPro) ProIconMark(size: 28, child: iconWell) else iconWell,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: showPro
                  ? proLockedTextColor(context)
                  : context.primaryText,
            ),
          ),
        ),
        Icon(LucideIcons.chevronRight, size: 16, color: context.faintText),
      ],
    );
  }
}
