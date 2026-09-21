import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const lime = Color(0xFFCDFF3A);
  static const limeDark = Color(0xFFA8D82F);
  static const limeAccent = Color(0xFF7A9E1F);

  /// Text selection fill — soft mint so it stays clean on dark surfaces
  /// (high-alpha neon lime reads as muddy olive).
  static const selectionDark = Color(0x5922E06A); // ~35% soft green
  static const selectionLight = Color(0x4D7A9E1F); // ~30% limeAccent
  static const selectionHandle = lime;

  /// Legacy brand purple (UI accents / wells — not the launcher plate).
  static const brandPurple = Color(0xFF8C52FF);

  static const ink = Color(0xFF0F0F0F);
  static const ink2 = Color(0xFF1A1A1A);
  static const ink3 = Color(0xFF2A2A2A);

  static const bg = Color(0xFFF2F2F2);
  static const bgAlt = Color(0xFFE8E8E8);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF0F0F0F);
  static const textSecondary = Color(0xFF666666);
  static const textMuted = Color(0xFF888888);
  static const textFaint = Color(0xFF999999);

  static const divider = Color(0xFFF2F2F2);

  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFB84E);
  static const info = Color(0xFF4ECDC4);
  static const violet = Color(0xFFA78BFA);

  static const bgFood = Color(0x40CDFF3A); // lime tint
  static const bgTransport = Color(0xFFFFE4E1);
  static const bgEntertainment = Color(0xFFE8E4FF);
  static const bgShopping = Color(0xFFFFF3D6);

  static const income = limeAccent;
  static const expense = Color(0xFFFF6B6B);
}
