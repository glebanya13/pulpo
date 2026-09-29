import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Translucent "liquid glass" chrome: blur + specular edge, like iOS 26.
/// Use for floating UI (nav, sheets, overlays) — not for dense lists or forms.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(100)),
    this.padding,
    /// Cheaper path while content scrolls underneath — must NOT change fill
    /// colors (that caused bottom-nav flash dark↔light on scroll).
    this.light = false,
    /// Icon / title-pill chrome — denser so ← / title / + stay readable.
    this.compact = false,
    /// Brand / home header — lighter frosted bar (not a darkened slab).
    this.airy = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool light;
  final bool compact;
  final bool airy;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    // `light` only cheapens blur — fill stays identical to avoid flicker.
    final sigma = light ? 6.0 : (compact ? 8.0 : 14.0);
    final shadowBlur = compact ? 8.0 : (light ? 10.0 : 20.0);
    final shadowY = compact ? 3.0 : 10.0;

    // Dark compact = control discs (← / Categorías / +) everywhere.
    // Dark default = floating bars (bottom nav).
    // Dark airy = home/brand ScreenTitlePill — lighter on purpose.
    final List<Color> fill;
    if (dark) {
      if (compact) {
        fill = const [
          Color(0xE6282828),
          Color(0xD61E1E1E),
        ];
      } else if (airy) {
        fill = [
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.05),
        ];
      } else {
        fill = const [
          Color(0xD92E2E2E),
          Color(0xC8242424),
        ];
      }
    } else {
      if (compact) {
        fill = [
          Colors.white.withValues(alpha: 0.94),
          Colors.white.withValues(alpha: 0.78),
        ];
      } else if (airy) {
        fill = [
          Colors.white.withValues(alpha: 0.78),
          Colors.white.withValues(alpha: 0.48),
        ];
      } else {
        fill = [
          Colors.white.withValues(alpha: 0.82),
          Colors.white.withValues(alpha: 0.58),
        ];
      }
    }

    final border = Border.all(
      color: Colors.white.withValues(
        alpha: dark ? (compact ? 0.22 : 0.20) : 0.72,
      ),
      width: 0.6,
    );

    final painted = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: fill,
        ),
        border: border,
      ),
      child: padding == null
          ? child
          : Padding(padding: padding!, child: child),
    );

    // While scrolling (`light`), skip live BackdropFilter — sampling the
    // moving list is what made the bar pulse light/dark every frame.
    final body = light
        ? painted
        : ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: painted,
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: dark
                  ? (compact ? 0.32 : 0.30)
                  : (compact ? 0.08 : 0.12),
            ),
            blurRadius: shadowBlur,
            offset: Offset(0, shadowY),
          ),
        ],
      ),
      child: light ? ClipRRect(borderRadius: borderRadius, child: body) : body,
    );
  }
}
