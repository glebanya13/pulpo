import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import '../widgets/common.dart';

/// Shown while GoRouter builds the first frame, or if routing fails briefly.
class AppBootFallback extends StatelessWidget {
  const AppBootFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.ink,
      child: Center(
        child: BrandLogo(size: 72),
      ),
    );
  }
}
