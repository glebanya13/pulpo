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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
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
          animationDuration: const Duration(milliseconds: 90),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.14);
            }
            return Colors.transparent;
          }),
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
      iconTheme: const IconThemeData(color: AppColors.ink),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: AppColors.textPrimary,
        iconColor: AppColors.ink,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.ink;
          return const Color(0xFFDDDDDD);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.limeAccent,
        selectionColor: AppColors.lime.withValues(alpha: 0.45),
        selectionHandleColor: AppColors.limeAccent,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    // Page shell = ink2 (gray). Cards lift to ink3. Pure black (ink) only for
    // intentional emphasized blocks — never as the screen backdrop.
    const bg = AppColors.ink2;
    const surface = AppColors.ink3;
    const surface2 = Color(0xFF333333);
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
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: surface2,
      surfaceContainerHigh: surface2,
      surfaceContainerHighest: surface2,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
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
          animationDuration: const Duration(milliseconds: 90),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.14);
            }
            return Colors.transparent;
          }),
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
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: Colors.white,
        iconColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.lime;
          return Colors.white.withValues(alpha: 0.22);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.lime,
        selectionColor: AppColors.lime.withValues(alpha: 0.45),
        selectionHandleColor: AppColors.lime,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Extension для доступа к адаптивным цветам через context.
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;

  /// Стандартная карточка (списки, tiles, форм-blocks).
  /// light → белый; dark → ink3 (над серой оболочкой ink2).
  Color get surface => Theme.of(this).cardColor;

  /// «Приподнятая» акцентная карточка (BalanceCard, BudgetSummary и т.п.).
  /// light → чёрная; dark → ink на серой оболочке ink2.
  Color get emphasized => AppColors.ink;

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
