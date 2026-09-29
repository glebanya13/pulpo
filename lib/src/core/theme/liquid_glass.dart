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
    /// Lower while content scrolls under the chrome (cheaper compositing).
    this.light = false,
    /// Icon-sized chrome — denser dark fill so ← / ✕ / + stay readable
    /// over lists (no full-width header scrim).
    this.compact = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final sigma = compact ? 8.0 : (light ? 10.0 : 14.0);
    final shadowBlur = compact ? 8.0 : (light ? 12.0 : 20.0);
    final shadowY = compact ? 3.0 : 10.0;

    // Dark compact = darkened control discs. Large headers stay airier so the
    // home brand bar doesn't read as a solid black slab.
    final List<Color> fill;
    if (dark) {
      if (compact) {
        fill = [
          const Color(0xE6282828),
          const Color(0xD61E1E1E),
        ];
      } else if (light) {
        fill = [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.07),
        ];
      } else {
        fill = [
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.05),
        ];
      }
    } else {
      if (compact) {
        fill = [
          Colors.white.withValues(alpha: 0.94),
          Colors.white.withValues(alpha: 0.78),
        ];
      } else if (light) {
        fill = [
          Colors.white.withValues(alpha: 0.88),
          Colors.white.withValues(alpha: 0.62),
        ];
      } else {
        fill = [
          Colors.white.withValues(alpha: 0.78),
          Colors.white.withValues(alpha: 0.48),
        ];
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: dark
                  ? (compact ? 0.32 : 0.28)
                  : (compact ? 0.08 : 0.12),
            ),
            blurRadius: shadowBlur,
            offset: Offset(0, shadowY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: fill,
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: dark ? (compact ? 0.22 : 0.26) : 0.72,
                ),
                width: 0.6,
              ),
            ),
            child: padding == null
                ? child
                : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}
