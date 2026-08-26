import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/app_info.dart';
import '../core/l10n/tr.dart';
import '../core/open_link.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'pressable.dart';

/// Brand mark: stacked MONEDERO — purple plate (light) / transparent lime (dark).
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.size,
    this.plate = true,
    this.onDarkSurface = false,
  });

  final double size;
  /// When false, only the mark (no rounded plate / shadow behind it).
  final bool plate;
  /// Use when the parent is dark even if the app theme is still light
  /// (onboarding, lock screen).
  final bool onDarkSurface;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    final dark = onDarkSurface || context.isDark;
    final asset = dark ? 'assets/logo_dark.png' : 'assets/logo_light.png';
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
      ),
    );

    if (!plate) {
      return SizedBox(width: size, height: size, child: mark);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: mark,
    );
  }
}

/// Title in a surface pill — matches cards / filters as part of the chrome.
class ScreenTitlePill extends StatelessWidget {
  const ScreenTitlePill({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
    this.large = false,
    this.expand = false,
  });

  final String title;
  final String? subtitle;
  /// Smaller muted line above the title (e.g. greeting).
  final String? eyebrow;
  /// Optional control inside the pill (e.g. profile on home).
  final Widget? trailing;
  final bool large;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final textBlock = Column(
      crossAxisAlignment:
          expand || large ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: large ? 13 : 12,
              fontWeight: FontWeight.w500,
              color: context.mutedText,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: large ? 22 : 15,
            fontWeight: FontWeight.w800,
            letterSpacing: large ? -0.6 : -0.2,
            height: 1.15,
            color: context.primaryText,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: large ? 13 : 12,
              fontWeight: FontWeight.w500,
              color: context.mutedText,
            ),
          ),
        ],
      ],
    );

    final child = Container(
      width: expand ? double.infinity : null,
      padding: EdgeInsets.fromLTRB(
        16,
        large ? 12 : 10,
        trailing != null ? 10 : 16,
        large ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(large ? 18 : 999),
      ),
      child: trailing == null
          ? textBlock
          : Row(
              children: [
                Expanded(child: textBlock),
                const SizedBox(width: 8),
                trailing!,
              ],
            ),
    );
    if (expand) return child;
    return Align(alignment: Alignment.centerLeft, child: child);
  }
}

/// Pins [header] above a scrollable list (same pattern as the home tab).
class StickyScrollPage extends StatelessWidget {
  const StickyScrollPage({
    super.key,
    required this.header,
    required this.children,
    this.controller,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 40),
    this.headerGap = 20,
    this.headerBottomPadding = 0,
    this.useSafeArea = true,
    this.physics,
  });

  final Widget header;
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsets padding;
  /// Space between sticky header and first list child.
  final double headerGap;
  /// Extra padding under the header inside the sticky bar (dashboard uses 10).
  final double headerBottomPadding;
  final bool useSafeArea;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: bg,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top,
              padding.right,
              headerBottomPadding,
            ),
            child: header,
          ),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            physics: physics,
            padding: EdgeInsets.fromLTRB(
              padding.left,
              headerGap,
              padding.right,
              padding.bottom,
            ),
            children: children,
          ),
        ),
      ],
    );
    if (!useSafeArea) return content;
    return SafeArea(child: content);
  }
}

/// Profile shortcut: avatar icon + localized “My account” label.
class MyAccountChip extends StatelessWidget {
  const MyAccountChip({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final iconColor = context.isDark ? AppColors.lime : AppColors.ink;
    return Pressable(
      onTap: () => context.push('/profile'),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.user, size: dense ? 16 : 18, color: iconColor),
            SizedBox(width: dense ? 5 : 6),
            Text(
              tr.myAccount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 11 : 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: context.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// WhatsApp support — opens [AppInfo.whatsAppUri] (username, not phone).
class WhatsAppSupportChip extends StatelessWidget {
  const WhatsAppSupportChip({super.key, this.dense = false});

  final bool dense;

  static const _green = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final size = dense ? 34.0 : 40.0;
    return Pressable(
      onTap: () => openAppLink(context, AppInfo.whatsAppUri),
      child: Semantics(
        button: true,
        label: 'WhatsApp',
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LucideIcons.messageCircle,
            size: dense ? 18 : 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// WhatsApp + account chip pair for main tab headers.
class HeaderSupportActions extends StatelessWidget {
  const HeaderSupportActions({super.key, this.dense = true});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WhatsAppSupportChip(dense: dense),
        SizedBox(width: dense ? 6 : 8),
        MyAccountChip(dense: dense),
      ],
    );
  }
}

/// Header страницы: back/action по краям, заголовок по центру в pill.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.first,
    this.second,
    this.subtitle,
    this.action,
    this.onBack,
  });

  final String first;
  final String? second;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onBack;

  static const _side = 42.0;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.15,
      color: context.primaryText,
    );

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          text: first,
          style: titleStyle,
          children: [
            if (second != null)
              TextSpan(
                text: second,
                style: titleStyle.copyWith(
                  color: context.isDark
                      ? AppColors.lime
                      : AppColors.limeAccent,
                ),
              ),
          ],
        ),
      ),
    );

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _side,
              height: _side,
              child: onBack != null
                  ? _RoundIconBtn(
                      icon: LucideIcons.arrowLeft,
                      onTap: onBack!,
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  // Leave room for side buttons; don't clip short titles oddly.
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width - (_side * 2) - 32,
                  ),
                  child: pill,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _side, minHeight: _side),
              child: Align(
                alignment: Alignment.centerRight,
                child: action ?? const SizedBox(width: _side, height: _side),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.mutedText,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dark = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => _RoundIconBtn(
        icon: icon,
        onTap: onTap,
        dark: dark,
      );
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({
    required this.icon,
    required this.onTap,
    this.dark = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isDark = dark || context.isDark;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18, color: isDark ? Colors.white : AppColors.ink),
      ),
    );
  }
}

/// section title (h3 слева, action-текст справа).
class SectTitle extends StatelessWidget {
  const SectTitle({super.key, required this.title, this.actionText, this.onAction});
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.primaryText,
            ),
          ),
          if (actionText != null)
            Pressable(
              onTap: onAction ?? () {},
              enabled: onAction != null,
              child: Text(
                actionText!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.isDark
                      ? AppColors.lime
                      : AppColors.limeAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Пилюля-переключатель. Ширина сегментов по длине подписи, чтобы
/// левый и правый край не «съезжали» из‑за короткого Todos и длинного Transferencia.
class TabsPill extends StatelessWidget {
  const TabsPill({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.limeActive = false,
  });
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final bool limeActive;

  @override
  Widget build(BuildContext context) {
    final weights = <int>[
      for (final t in tabs) t.trim().length.clamp(4, 18),
    ];
    final total = weights.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inner = constraints.maxWidth;
          var left = 0.0;
          for (var i = 0; i < index; i++) {
            left += inner * (weights[i] / total);
          }
          final segW = inner * (weights[index] / total);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: left,
                width: segW,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: limeActive
                        ? AppColors.lime
                        : (context.isDark ? AppColors.ink3 : AppColors.ink),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      flex: weights[i],
                      child: Pressable(
                        onTap: () => onChanged(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: index == i
                                    ? (limeActive
                                        ? AppColors.ink
                                        : Colors.white)
                                    : context.mutedText,
                              ),
                              child: Text(
                                tabs[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Тумблер.
class BudgetToggle extends StatelessWidget {
  const BudgetToggle({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => onChanged(!value),
      scale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 26,
        decoration: BoxDecoration(
          color: value ? AppColors.lime : (context.isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Пустое состояние — крупный emoji-иллюстратор и текст.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.onAction,
    this.background = AppColors.bgFood,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? action;
  final VoidCallback? onAction;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              child: Icon(
                icon,
                size: 56,
                color: context.isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.primaryText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.mutedText,
                height: 1.4,
              ),
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 20),
              Pressable(
                onTap: onAction!,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(action!,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Простой скелетон.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.height = 14,
    this.width = double.infinity,
    this.radius = 10,
  });
  final double height;
  final double width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final mid = context.isDark ? const Color(0xFF333333) : const Color(0xFFF2F2F2);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _c.value, 0),
              end: Alignment(1 + 2 * _c.value, 0),
              colors: [base, mid, base],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

/// Ошибка.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return EmptyState(
      icon: LucideIcons.alertTriangle,
      title: tr.errorTitle,
      description: message,
      action: onRetry != null ? tr.retry : null,
      onAction: onRetry,
      background: const Color(0xFFFFE4E1),
    );
  }
}

/// Badge (маленький статус-лейбл).
class BudgetBadge extends StatelessWidget {
  const BudgetBadge({super.key, required this.text, this.tone = BadgeTone.lime});
  final String text;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (tone) {
      case BadgeTone.lime:
        bg = AppColors.lime;
        fg = AppColors.ink;
        break;
      case BadgeTone.red:
        bg = context.isDark
            ? AppColors.danger.withValues(alpha: 0.28)
            : AppColors.danger;
        fg = context.isDark ? const Color(0xFFFF8A8A) : Colors.white;
        break;
      case BadgeTone.green:
        bg = context.isDark
            ? AppColors.lime.withValues(alpha: 0.28)
            : AppColors.lime;
        fg = context.isDark ? AppColors.lime : AppColors.ink;
        break;
      case BadgeTone.orange:
        bg = context.isDark
            ? AppColors.warning.withValues(alpha: 0.28)
            : AppColors.warning;
        fg = context.isDark ? const Color(0xFFFFD08A) : AppColors.ink;
        break;
      case BadgeTone.gray:
        bg = context.isDark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFE8E8E8);
        fg = context.primaryText;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

enum BadgeTone { lime, red, green, orange, gray }

/// Скругленная карточка контента.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radius = 20,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
          color: color ?? context.surface,
          borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}
