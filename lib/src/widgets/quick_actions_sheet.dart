import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/l10n/tr.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/color_well.dart';
import '../core/theme/liquid_glass.dart';
import 'pressable.dart';

Future<void> showQuickActionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _QuickActionsSheet(),
  );
}

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet();

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return LiquidGlass(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.handleBar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Action(
                  icon: LucideIcons.arrowDownRight,
                  color: const Color(0xFF8BD44A),
                  label: tr.income,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add?type=income');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Action(
                  icon: LucideIcons.arrowUpRight,
                  color: const Color(0xFFFF5C5C),
                  label: tr.expense,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add?type=expense');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Action(
                  icon: LucideIcons.arrowLeftRight,
                  color: const Color(0xFF7C6CFF),
                  label: tr.transferBetweenAccounts,
                  hint: tr.transferBetweenHint,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add?type=transfer');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Action(
                  icon: LucideIcons.send,
                  color: const Color(0xFFFFB020),
                  label: tr.transferExternal,
                  hint: tr.transferExternalHint,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add?type=expense&mode=external');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.hint,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.wellBg(color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: context.wellFg(color)),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.primaryText,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  color: context.mutedText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
