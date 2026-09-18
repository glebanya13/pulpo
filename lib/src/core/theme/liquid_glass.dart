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
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final sigma = light ? 10.0 : 14.0;
    final shadowBlur = light ? 12.0 : 20.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.38 : 0.12),
            blurRadius: shadowBlur,
            offset: const Offset(0, 10),
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
                colors: dark
                    ? [
                        Colors.white.withValues(alpha: light ? 0.22 : 0.18),
                        Colors.white.withValues(alpha: light ? 0.10 : 0.06),
                      ]
                    : [
                        Colors.white.withValues(alpha: light ? 0.88 : 0.78),
                        Colors.white.withValues(alpha: light ? 0.62 : 0.48),
                      ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.28 : 0.72),
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
