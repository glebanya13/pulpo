import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/l10n/tr.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'pressable.dart';

/// Header страницы: title с акцентом на 2-й части + subtitle + правая кнопка.
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

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          _RoundIconBtn(icon: LucideIcons.arrowLeft, onTap: onBack!),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: first,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: context.primaryText,
                    height: 1.1,
                  ),
                  children: [
                    if (second != null)
                      TextSpan(
                        text: second,
                        style: TextStyle(
                            color: context.isDark
                                ? AppColors.lime
                                : AppColors.limeAccent),
                      ),
                  ],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style:
                        TextStyle(fontSize: 12, color: context.mutedText)),
              ],
            ],
          ),
        ),
        if (action != null) action!,
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
    final weights = [
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
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
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
                              child: Text(tabs[i], maxLines: 1),
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
          color: value ? AppColors.lime : const Color(0xFFDDDDDD),
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
              child: Icon(icon, size: 56, color: AppColors.ink),
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
              colors: const [
                Color(0xFFE8E8E8),
                Color(0xFFF2F2F2),
                Color(0xFFE8E8E8),
              ],
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
