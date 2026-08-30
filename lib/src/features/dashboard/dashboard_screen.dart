import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/pressable.dart';
import '../../widgets/common.dart';
import '../../widgets/pro_badge.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/money_format.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../core/pro/pro_controller.dart';
import '../../widgets/reset_scroll_when_obscured.dart';
import 'monthly_calendar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final total = ref.watch(totalBalanceProvider);
    final currency = settings.baseCurrency;
    final fxApprox = ref.watch(fxApproximateProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final txsAsync = ref.watch(allTransactionsProvider);

    void retryBalance() {
      ref.invalidate(accountsProvider);
      ref.invalidate(allTransactionsProvider);
    }

    return ResetScrollWhenObscured(
      tabPath: '/',
      builder: (context, scroll) {
        final pad = AppSpacing.tabPagePadding(context);
        return StickyScrollPage(
          useSafeArea: false,
          controller: scroll,
          padding: pad,
          headerGap: 0,
          headerBottomPadding: 10,
          header: ScreenTitlePill(
            title: settings.userName,
            eyebrow: tr.greetingForHour(DateTime.now().hour),
            large: true,
            expand: true,
            trailing: const HeaderSupportActions(dense: true),
          ),
          children: [
            AsyncValuesGate(
              values: [accountsAsync, txsAsync],
              onRetry: retryBalance,
              child: _BalanceActionCard(
                total: total,
                currency: currency,
                fxApproximate: fxApprox.isNotEmpty,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr.calendar,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Pressable(
                  onTap: () => context.go('/transactions'),
                  child: Text(
                    tr.viewHistory,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.limeAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const MonthlyCalendar(),
          ],
        );
      },
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onDark = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final chipBg = onDark
        ? Colors.white.withValues(alpha: 0.12)
        : context.surface;
    final iconColor = onDark ? Colors.white : context.primaryText;

    return Expanded(
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          button: true,
          child: Pressable(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceActionCard extends ConsumerStatefulWidget {
  const _BalanceActionCard({
    required this.total,
    required this.currency,
    this.fxApproximate = false,
  });

  final double total;
  final String currency;
  final bool fxApproximate;

  @override
  ConsumerState<_BalanceActionCard> createState() =>
      _BalanceActionCardState();
}

class _BalanceActionCardState extends ConsumerState<_BalanceActionCard> {
  final _menuAnchorKey = GlobalKey();
  OverlayEntry? _menuEntry;
  final _menuOverlayKey = GlobalKey<_ManagementMenuOverlayState>();

  @override
  void dispose() {
    _menuEntry?.remove();
    _menuEntry = null;
    super.dispose();
  }

  void _hideMenu({VoidCallback? then}) {
    final overlay = _menuOverlayKey.currentState;
    if (overlay == null) {
      _menuEntry?.remove();
      _menuEntry = null;
      then?.call();
      return;
    }
    overlay.dismiss(then: () {
      _menuEntry?.remove();
      _menuEntry = null;
      then?.call();
    });
  }

  void _showManagementMenu() {
    if (_menuEntry != null) {
      _hideMenu();
      return;
    }

    final anchorContext = _menuAnchorKey.currentContext;
    if (anchorContext == null) return;
    final box = anchorContext.findRenderObject()! as RenderBox;
    final screen = MediaQuery.sizeOf(context);
    final topLeft = box.localToGlobal(Offset.zero);
    const menuWidth = 288.0;
    final left = (topLeft.dx + box.size.width - menuWidth)
        .clamp(16.0, screen.width - menuWidth - 16);
    final top = topLeft.dy + box.size.height + 8;
    final tr = Tr.of(context);
    final isPro = ref.read(proControllerProvider).isPro;
    final items = _managementItems(tr);
    final host = Overlay.of(context);

    _menuEntry = OverlayEntry(
      builder: (overlayContext) => _ManagementMenuOverlay(
        key: _menuOverlayKey,
        left: left,
        top: top,
        menuWidth: menuWidth,
        header: tr.management,
        isPro: isPro,
        items: items,
        onSelect: (route) {
          _hideMenu(then: () {
            if (mounted) context.push(route);
          });
        },
        onDismiss: () {
          _menuEntry?.remove();
          _menuEntry = null;
        },
      ),
    );
    host.insert(_menuEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
      decoration: BoxDecoration(
        color: context.emphasized,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.emphasizedBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tr.totalBalance,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(widget.total, widget.currency),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    if (widget.fxApproximate) ...[
                      const SizedBox(height: 6),
                      Text(
                        tr.fxApproximateBalance,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tooltip(
                message: tr.management,
                child: Semantics(
                  label: tr.management,
                  button: true,
                  child: Pressable(
                    key: _menuAnchorKey,
                    onTap: _showManagementMenu,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.chevronDown,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickChip(
                icon: LucideIcons.plus,
                label: tr.income,
                onDark: true,
                onTap: () => context.push('/add?type=income'),
              ),
              const SizedBox(width: 6),
              _QuickChip(
                icon: LucideIcons.minus,
                label: tr.expense,
                onDark: true,
                onTap: () => context.push('/add?type=expense'),
              ),
              const SizedBox(width: 6),
              _QuickChip(
                icon: LucideIcons.arrowLeftRight,
                label: tr.transferBetweenAccounts,
                onDark: true,
                onTap: () => context.push('/add?type=transfer'),
              ),
              const SizedBox(width: 6),
              _QuickChip(
                icon: LucideIcons.send,
                label: tr.transferExternal,
                onDark: true,
                onTap: () =>
                    context.push('/add?type=expense&mode=external'),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

List<(IconData, String, String, Color, bool)> _managementItems(Tr tr) => [
      (LucideIcons.wallet, tr.accounts, '/accounts', const Color(0xFF8BD44A), false),
      (LucideIcons.pieChart, tr.budgets, '/budgets', const Color(0xFFFFB020), false),
      (LucideIcons.usersRound, tr.sharedBudgetTitle, '/shared-budget', const Color(0xFF7C6CFF), true),
      (LucideIcons.users, tr.debts, '/debts', const Color(0xFFFF5C5C), false),
      (LucideIcons.tv, tr.subscriptions, '/subscriptions', const Color(0xFF7C6CFF), false),
      (LucideIcons.repeat, tr.recurringOps, '/recurring', const Color(0xFF2EB5FF), false),
      (LucideIcons.target, tr.goals, '/goals', const Color(0xFFCDFF3A), false),
      (LucideIcons.layers, tr.categories, '/categories', const Color(0xFFD4F5E0), false),
    ];

class _ManagementMenuOverlay extends StatefulWidget {
  const _ManagementMenuOverlay({
    super.key,
    required this.left,
    required this.top,
    required this.menuWidth,
    required this.header,
    required this.isPro,
    required this.items,
    required this.onSelect,
    required this.onDismiss,
  });

  final double left;
  final double top;
  final double menuWidth;
  final String header;
  final bool isPro;
  final List<(IconData, String, String, Color, bool)> items;
  final ValueChanged<String> onSelect;
  final VoidCallback onDismiss;

  @override
  State<_ManagementMenuOverlay> createState() => _ManagementMenuOverlayState();
}

class _ManagementMenuOverlayState extends State<_ManagementMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    // Start fully visible — no open animation (instant show).
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1,
    );
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> dismiss({VoidCallback? then}) async {
    if (!mounted) return;
    await _fade.reverse(from: 1);
    widget.onDismiss();
    then?.call();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return FadeTransition(
      opacity: _fade,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => dismiss(),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: dark ? 0.38 : 0.2),
                ),
              ),
            ),
            Positioned(
              left: widget.left,
              top: widget.top,
              width: widget.menuWidth,
              child: RepaintBoundary(
                child: Material(
                  color: context.surface,
                  elevation: 8,
                  shadowColor:
                      Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          widget.header,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: context.mutedText,
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: context.divider),
                      for (var i = 0; i < widget.items.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: context.divider,
                          ),
                        InkWell(
                          onTap: () => widget.onSelect(widget.items[i].$3),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: _ManagementMenuRow(
                              icon: widget.items[i].$1,
                              label: widget.items[i].$2,
                              color: widget.items[i].$4,
                              showPro: widget.items[i].$5 && !widget.isPro,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
