import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const _family = 'Inter';

  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 64,
    fontWeight: FontWeight.w800,
    height: 1,
    letterSpacing: -3,
    color: AppColors.textPrimary,
  );

  static const h1 = TextStyle(
    fontFamily: _family,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    height: 1.05,
    color: AppColors.textPrimary,
  );

  static const h2 = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const bodyMuted = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const label = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textFaint,
  );

  static const overline = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: AppColors.textMuted,
  );

  static const button = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const amountBig = TextStyle(
    fontFamily: _family,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
  );
}
