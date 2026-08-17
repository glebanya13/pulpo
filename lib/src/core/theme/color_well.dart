import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';

/// Старые пастельные seed-цвета → насыщенные.
const pastelColorRemap = <int, int>{
  0x40CDFF3A: 0xFF8BD44A,
  0xFFFFE4E1: 0xFFFF5C5C,
  0xFFE8E4FF: 0xFF7C6CFF,
  0xFFFFF3D6: 0xFFFFB020,
  0xFFD4F5E0: 0xFF3DDC84,
  0xFFE0F2FE: 0xFF2EB5FF,
  0xFFF2F2F2: 0xFF8A94A6,
};

/// Палитра для выбора цвета категории.
const categoryPalette = <int>[
  0xFFCDFF3A,
  0xFFFF5C5C,
  0xFF7C6CFF,
  0xFFFFB020,
  0xFF3DDC84,
  0xFF2EB5FF,
  0xFFFF7A45,
  0xFFFF5CA8,
  0xFF8A94A6,
];

extension VividColorX on Color {
  /// Делает бледный/полупрозрачный цвет нормальным акцентом.
  Color get asVivid {
    final remapped = pastelColorRemap[toARGB32()];
    if (remapped != null) return Color(remapped);
    if (a < 0.99) return const Color(0xFF8BD44A);
    final hsl = HSLColor.fromColor(this);
    if (hsl.saturation < 0.12) return const Color(0xFF8A94A6);
    if (hsl.lightness > 0.78) {
      return hsl
          .withSaturation((hsl.saturation + 0.4).clamp(0.55, 0.95))
          .withLightness(0.56)
          .toColor();
    }
    return this;
  }
}

extension ColorWellX on BuildContext {
  Color wellBg(Color stored) {
    final v = stored.asVivid;
    if (isDark) {
      return Color.lerp(const Color(0xFF1C1C1C), v, 0.16)!;
    }
    return Color.lerp(Colors.white, v, 0.34)!;
  }

  Color wellFg(Color stored) {
    final v = stored.asVivid;
    final hsl = HSLColor.fromColor(v);
    if (isDark) {
      return hsl
          .withSaturation((hsl.saturation * 0.55).clamp(0.25, 0.7))
          .withLightness((hsl.lightness * 0.55).clamp(0.38, 0.55))
          .toColor();
    }
    return hsl.withLightness((hsl.lightness * 0.42).clamp(0.18, 0.38)).toColor();
  }
}

/// Иконка в цветном квадрате — одинаково читается в light и dark.
class ColorWellIcon extends StatelessWidget {
  const ColorWellIcon({
    super.key,
    required this.color,
    required this.icon,
    this.size = 42,
    this.iconSize = 20,
    this.radius = 14,
  });

  final Color color;
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.wellBg(color),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: context.wellFg(color)),
    );
  }
}

/// Нейтральный колодец для строк без категории (счёт, дата).
class NeutralWellIcon extends StatelessWidget {
  const NeutralWellIcon({
    super.key,
    required this.icon,
    this.size = 32,
    this.iconSize = 14,
    this.radius = 10,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: context.primaryText),
    );
  }
}
