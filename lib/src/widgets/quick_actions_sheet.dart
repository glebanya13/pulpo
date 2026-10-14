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

enum _QuickAction {
  income,
  expense,
  assistant,
  scanReceipt,
  transfer,
  external,
}

/// Shared density for every tile in the sheet.
const _kRadius = 14.0;
const _kPad = EdgeInsets.fromLTRB(12, 12, 12, 12);
const _kGap = 8.0;
const _kIcon = 32.0;
const _kIconGlyph = 15.0;
const _kTitleSize = 13.0;
const _kHintSize = 11.0;

Future<void> showQuickActionsSheet(BuildContext context, WidgetRef ref) async {
  final action = await showModalBottomSheet<_QuickAction>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _QuickActionsSheet(),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _QuickAction.income:
      context.push('/add?type=income');
    case _QuickAction.expense:
      context.push('/add?type=expense');
    case _QuickAction.transfer:
      context.push('/add?type=transfer');
    case _QuickAction.external:
      context.push('/add?type=expense&mode=external');
    case _QuickAction.assistant:
      if (!await requireAi(context, ref, allowFreeEnergy: true)) return;
      if (context.mounted) context.push('/assistant');
    case _QuickAction.scanReceipt:
      if (!await requireAi(context, ref, allowFreeEnergy: true)) return;
      if (context.mounted) context.push('/assistant?scanReceipt=1');
  }
}

class _QuickActionsSheet extends ConsumerWidget {
  const _QuickActionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final isPro = ref.watch(proControllerProvider).isPro;
    final energy = ref.watch(assistantEnergyProvider);
    final locked = !isPro && !energy.hasEnergy;

    return LiquidGlass(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.handleBar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: LucideIcons.arrowDownRight,
                  color: const Color(0xFF8BD44A),
                  title: tr.income,
                  onTap: () => Navigator.pop(context, _QuickAction.income),
                ),
              ),
              const SizedBox(width: _kGap),
              Expanded(
                child: _Tile(
                  icon: LucideIcons.arrowUpRight,
                  color: const Color(0xFFFF5C5C),
                  title: tr.expense,
                  onTap: () => Navigator.pop(context, _QuickAction.expense),
                ),
              ),
            ],
          ),
          const SizedBox(height: _kGap),
          _WideTile(
            onTap: () => Navigator.pop(context, _QuickAction.assistant),
            gradient: true,
            leading: locked
                ? const ProIconMark(
                    size: _kIcon,
                    child: AiAssistantMark(size: _kIcon),
                  )
                : const AiAssistantMark(size: _kIcon),
            title: tr.aiChatTitle,
            subtitle: tr.aiVoiceEmptyHint,
            titleColor: Colors.white,
            subtitleColor: Colors.white.withValues(alpha: 0.85),
            trailing: locked
                ? const ProBadge(dense: true)
                : (!isPro
                    ? Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.zap,
                              size: 12,
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
                    : Icon(
                        LucideIcons.mic,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      )),
          ),
          const SizedBox(height: _kGap),
          _WideTile(
            onTap: () => Navigator.pop(context, _QuickAction.scanReceipt),
            borderColor: AppColors.lime.withValues(alpha: 0.35),
            leading: ColorWellIcon(
              color: AppColors.bgFood,
              icon: LucideIcons.receiptEuro,
              size: _kIcon,
              iconSize: _kIconGlyph,
              radius: 10,
            ),
            title: tr.aiRecognizeReceipt,
            subtitle: tr.receipt,
            trailing: locked
                ? const ProBadge(dense: true)
                : Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: context.faintText,
                  ),
          ),
          const SizedBox(height: _kGap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Tile(
                    icon: LucideIcons.arrowLeftRight,
                    color: AppColors.info,
                    title: tr.transferBetweenAccounts,
                    subtitle: tr.transferBetweenHint,
                    onTap: () =>
                        Navigator.pop(context, _QuickAction.transfer),
                  ),
                ),
                const SizedBox(width: _kGap),
                Expanded(
                  child: _Tile(
                    icon: LucideIcons.send,
                    color: const Color(0xFFFFB020),
                    title: tr.transferExternal,
                    subtitle: tr.transferExternalHint,
                    onTap: () =>
                        Navigator.pop(context, _QuickAction.external),
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: _kPad,
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: _kIcon,
              height: _kIcon,
              decoration: BoxDecoration(
                color: context.wellBg(color),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: _kIconGlyph, color: context.wellFg(color)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _kTitleSize,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: context.primaryText,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _kHintSize,
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

class _WideTile extends StatelessWidget {
  const _WideTile({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.gradient = false,
    this.borderColor,
    this.titleColor,
    this.subtitleColor,
  });

  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool gradient;
  final Color? borderColor;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: _kPad,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kRadius),
          color: gradient ? null : context.surface,
          gradient: gradient
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF8B7CFF),
                    AppColors.violet,
                  ],
                )
              : null,
          border: borderColor == null ? null : Border.all(color: borderColor!),
          boxShadow: gradient
              ? [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _kTitleSize,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: titleColor ?? context.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _kHintSize,
                      height: 1.25,
                      color: subtitleColor ?? context.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}
