import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/l10n/tr.dart';
import '../core/theme/app_colors.dart';

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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Action(
                  icon: LucideIcons.arrowDownRight,
                  color: AppColors.bgFood,
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
                  color: const Color(0xFFFFE4E1),
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
                  color: const Color(0xFFE0F2FE),
                  label: tr.transferBetweenAccounts,
                  hint: tr.transferBetweenHint,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/transfer');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Action(
                  icon: LucideIcons.send,
                  color: const Color(0xFFFFF3D6),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
