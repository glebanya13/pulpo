import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.ink,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          // linear-gradient(160deg, #1a1a1a 0%, #0F0F0F 100%)
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.6, -1),
              end: Alignment(0.6, 1),
              colors: [AppColors.ink2, AppColors.ink],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandLogo(size: 52, plate: false),
                        const SizedBox(width: 12),
                        Text(
                          'MONEDERO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cards (flex:1 — растягиваются в оставшуюся высоту)
                  const Expanded(child: _HeroCards()),

                  // Title
                  _Title(
                    first: _splitFirst(tr.takeControlOf),
                    accent: tr.finance,
                  ),
                  const SizedBox(height: 16),

                  // Desc
                  Text(
                    tr.onboardingSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Dots
                  const Row(
                    children: [
                      _Dot(active: true),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Primary button
                  Pressable(
                    onTap: () => context.push('/onboarding/setup'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          tr.getStarted,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Отделяет вспомогательный префикс из "Take control\nof your" — часть до \n
  String _splitFirst(String value) => value;
}

class _Title extends StatelessWidget {
  const _Title({required this.first, required this.accent});
  final String first;
  final String accent;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -1.5,
        ),
        children: [
          TextSpan(text: '$first '),
          TextSpan(
            text: accent,
            style: const TextStyle(color: AppColors.lime),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 22 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.lime : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _HeroCards extends StatefulWidget {
  const _HeroCards();

  @override
  State<_HeroCards> createState() => _HeroCardsState();
}

class _HeroCardsState extends State<_HeroCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const cardW = 200.0;
      final cx = w / 2 - cardW / 2;
      final cy = h / 2 - 90;

      Widget fadeSlide(double begin, Widget child) {
        final curved = CurvedAnimation(
          parent: _ctrl,
          curve: Interval(begin, (begin + 0.45).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: cx,
            top: cy - 30,
            child: fadeSlide(
              0.0,
              Transform.rotate(
                angle: -0.14,
                child: _Card(
                  label: Tr.of(context).categoryName('salary'),
                  amount: '€3,200',
                  sub: '+ 1',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.lime, AppColors.limeDark],
                  ),
                  textDark: true,
                ),
              ),
            ),
          ),
          Positioned(
            left: cx - 30,
            top: cy + 80,
            child: fadeSlide(
              0.12,
              Transform.rotate(
                angle: -0.035,
                child: _Card(
                  label: Tr.of(context).categoryName('food'),
                  amount: '€420',
                  sub: Tr.of(context).periodThisMonth,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3A3A3A), Color(0xFF252525)],
                  ),
                  borderColor: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Positioned(
            left: cx + 40,
            top: cy + 40,
            child: fadeSlide(
              0.22,
              Transform.rotate(
                angle: 0.105,
                child: _Card(
                  label: Tr.of(context).goals,
                  amount: '€8,750',
                  sub: '68%',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A2A2A), AppColors.ink2],
                  ),
                  borderColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.label,
    required this.amount,
    required this.sub,
    required this.gradient,
    this.textDark = false,
    this.borderColor,
  });

  final String label;
  final String amount;
  final String sub;
  final Gradient gradient;
  final bool textDark;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final color = textDark ? AppColors.ink : Colors.white;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
