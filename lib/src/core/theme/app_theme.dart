import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.lime,
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.lime,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      cardColor: AppColors.surface,
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        headlineSmall: AppTypography.h3,
        titleLarge: AppTypography.title,
        titleMedium: AppTypography.sectionTitle,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.bodyMuted,
        labelLarge: AppTypography.button,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.caption,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.rLg)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: AppTypography.button,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.rPill)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData dark() {
    const bg = AppColors.ink;
    const surface = AppColors.ink2;
    const surface2 = AppColors.ink3;
    const onSurface = Colors.white;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.lime,
      brightness: Brightness.dark,
      primary: AppColors.lime,
      onPrimary: AppColors.ink,
      secondary: AppColors.lime,
      onSecondary: AppColors.ink,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surface2,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter', fontSize: 64, fontWeight: FontWeight.w800,
          height: 1, letterSpacing: -3, color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Inter', fontSize: 38, fontWeight: FontWeight.w800,
          letterSpacing: -1.5, height: 1.05, color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w800,
          letterSpacing: -1, height: 1.1, color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800,
          letterSpacing: -0.5, color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400,
          color: Colors.white54,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.rLg)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 15,
            fontWeight: FontWeight.w700, color: AppColors.ink,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.rPill)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
          thickness: 1,
          space: 1,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}

/// Extension для доступа к адаптивным цветам через context.
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;

  /// Стандартная карточка (списки, tiles, форм-blocks).
  /// light → белый; dark → ink2.
  Color get surface => Theme.of(this).cardColor;

  /// «Приподнятая» акцентная карточка. В light-дизайне была чёрная (BalanceCard,
  /// BudgetSummary, NetWorth, BottomNav, insight cards). В dark bg=ink она сливается —
  /// поднимаем до ink3.
  Color get emphasized =>
      isDark ? AppColors.ink3 : AppColors.ink;

  /// Тонкая рамка вокруг emphasized-карточек — помогает выделить их на dark fone.
  Color get emphasizedBorder =>
      isDark ? Colors.white.withValues(alpha: 0.06) : Colors.transparent;

  Color get primaryText => Theme.of(this).colorScheme.onSurface;
  Color get mutedText => isDark
      ? Colors.white.withValues(alpha: 0.72)
      : AppColors.textMuted;
  Color get faintText =>
      isDark ? Colors.white.withValues(alpha: 0.42) : AppColors.textFaint;

  /// Разделитель между строк — чуть плотнее в dark для читаемости.
  Color get divider => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : AppColors.divider;

  /// Пустой трек progress-bar (сзади заливки).
  Color get progressTrack => isDark
      ? Colors.white.withValues(alpha: 0.1)
      : const Color(0xFFF2F2F2);

  /// Акцент lime, адаптированный по яркости фона (для ссылок/итогов).
  Color get accent => isDark ? AppColors.lime : AppColors.limeAccent;

  /// Полоска-хендл вверху bottom sheet.
  Color get handleBar => isDark
      ? Colors.white.withValues(alpha: 0.24)
      : const Color(0xFFDDDDDD);
}
