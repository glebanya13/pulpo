import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Translucent "liquid glass" chrome: blur + specular rim, like iOS 26.
/// Use for floating UI (nav, sheets, overlays) — not for dense lists or forms.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(100)),
    this.padding,
    /// Cheaper path: skip live blur (static frosted fill only).
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
    final sigma = light ? 0.0 : (compact ? 12.0 : 22.0);
    final shadowBlur = compact ? 10.0 : 28.0;
    final shadowY = compact ? 4.0 : 12.0;
    final rimWidth = compact ? 0.55 : 0.75;

    // Tint over the blur — translucent so frost reads as glass, not a slab.
    final List<Color> fill;
    if (dark) {
      if (compact) {
        fill = [
          Colors.white.withValues(alpha: 0.24),
          Colors.white.withValues(alpha: 0.11),
        ];
      } else if (airy) {
        fill = [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.06),
        ];
      } else {
        // Floating pill (bottom nav) — charcoal frost like iOS liquid glass.
        fill = [
          Colors.white.withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.04),
        ];
      }
    } else {
      if (compact) {
        fill = [
          Colors.white.withValues(alpha: 0.90),
          Colors.white.withValues(alpha: 0.64),
        ];
      } else if (airy) {
        fill = [
          Colors.white.withValues(alpha: 0.74),
          Colors.white.withValues(alpha: 0.44),
        ];
      } else {
        fill = [
          Colors.white.withValues(alpha: 0.80),
          Colors.white.withValues(alpha: 0.50),
          Colors.white.withValues(alpha: 0.40),
        ];
      }
    }

    // Outer rim: bright top-left specular → soft bottom.
    final rim = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [
              Colors.white.withValues(alpha: compact ? 0.58 : 0.68),
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.30),
            ]
          : [
              Colors.white.withValues(alpha: 0.98),
              Colors.white.withValues(alpha: 0.50),
              Colors.black.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.75),
            ],
      stops: const [0.0, 0.28, 0.72, 1.0],
    );

    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: fill,
          stops: fill.length == 3
              ? const [0.0, 0.42, 1.0]
              : const [0.0, 1.0],
        ),
      ),
      child: padding == null
          ? child
          : Padding(padding: padding!, child: child),
    );

    if (sigma > 0) {
      body = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: body,
      );
    }

    body = ClipRRect(
      borderRadius: borderRadius,
      child: body,
    );

    // Specular rim = gradient shell with hairline inset.
    body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: rim,
      ),
      child: Padding(
        padding: EdgeInsets.all(rimWidth),
        child: body,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: dark
                  ? (compact ? 0.40 : 0.48)
                  : (compact ? 0.10 : 0.18),
            ),
            blurRadius: shadowBlur,
            offset: Offset(0, shadowY),
            spreadRadius: compact ? 0 : -2,
          ),
        ],
      ),
      child: body,
    );
  }
}
