import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/l10n/tr.dart';
import '../core/ai/assistant_energy.dart';
import '../core/pro/pro_controller.dart';
import '../core/pro/pro_guard.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/color_well.dart';
import '../core/theme/liquid_glass.dart';
import 'pressable.dart';
import 'pro_badge.dart';
import 'ai_assistant_mark.dart';

Future<void> showQuickActionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _QuickActionsSheet(),
  );
}

class _QuickActionsSheet extends ConsumerWidget {
  const _QuickActionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final isPro = ref.watch(proControllerProvider).isPro;
    final energy = ref.watch(assistantEnergyProvider);
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
                  onTap: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 220));
                    if (context.mounted) context.push('/add?type=income');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Action(
                  icon: LucideIcons.arrowUpRight,
                  color: const Color(0xFFFF5C5C),
                  label: tr.expense,
                  onTap: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 220));
                    if (context.mounted) context.push('/add?type=expense');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Pressable(
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 220));
              if (!context.mounted) return;
              if (!await requireAi(context, ref, allowFreeEnergy: true)) return;
              if (context.mounted) context.push('/assistant');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF8B7CFF),
                    AppColors.violet,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (!isPro && !energy.hasEnergy)
                    const ProIconMark(
                      size: 36,
                      child: AiAssistantMark(size: 36),
                    )
                  else
                    const AiAssistantMark(size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.aiChatTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr.aiVoiceEmptyHint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.25,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPro && !energy.hasEnergy)
                    const ProBadge(dense: true)
                  else if (!isPro)
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.zap,
                            size: 13,
                            color: AppColors.lime,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${energy.units}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(
                      LucideIcons.mic,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Pressable(
            onTap: () async {
              Navigator.pop(context);
              if (!await requireAi(context, ref, allowFreeEnergy: true)) {
                return;
              }
              if (context.mounted) {
                context.push('/assistant?scanReceipt=1');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.lime.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  ColorWellIcon(
                    color: AppColors.bgFood,
                    icon: LucideIcons.receiptEuro,
                    size: 42,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.aiRecognizeReceipt,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr.receipt,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPro && !energy.hasEnergy)
                    const ProBadge(dense: true)
                  else
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: context.faintText,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Action(
                    icon: LucideIcons.arrowLeftRight,
                    color: AppColors.info,
                    label: tr.transferBetweenAccounts,
                    hint: tr.transferBetweenHint,
                    onTap: () async {
                      Navigator.pop(context);
                      await Future.delayed(const Duration(milliseconds: 220));
                      if (context.mounted) context.push('/add?type=transfer');
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
                    onTap: () async {
                      Navigator.pop(context);
                      await Future.delayed(const Duration(milliseconds: 220));
                      if (context.mounted) context.push('/add?type=expense&mode=external');
                    },
                  ),
                ),
              ],
            ),
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
        width: double.infinity,
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
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    hint!,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.3,
                      color: context.mutedText,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
