import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/app_info.dart';
import '../../core/l10n/tr.dart';
import '../../core/open_link.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(first: tr.about, onBack: () => context.pop()),
        headerGap: 24,
        children: [
            Center(
              child: BrandLogo(size: 72),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Monedero',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${tr.version} ${AppInfo.version}',
                style: TextStyle(fontSize: 13, color: context.mutedText),
              ),
            ),
            const SizedBox(height: 24),
            _Card(
              children: [
                _LinkRow(
                  icon: LucideIcons.shield,
                  title: tr.privacyPolicy,
                  onTap: () => openAppLink(context, AppInfo.privacyUri),
                ),
                _LinkRow(
                  icon: LucideIcons.fileText,
                  title: tr.termsOfUse,
                  onTap: () => openAppLink(context, AppInfo.termsUri),
                ),
                _LinkRow(
                  icon: LucideIcons.lifeBuoy,
                  title: tr.contactSupport,
                  onTap: () => openAppLink(context, AppInfo.supportUri),
                ),
                _LinkRow(
                  icon: LucideIcons.messageCircle,
                  title: 'WhatsApp',
                  onTap: () => openAppLink(context, AppInfo.whatsAppUri),
                ),
                _LinkRow(
                  icon: LucideIcons.mail,
                  title: AppInfo.supportEmail,
                  onTap: () => openAppLink(context, AppInfo.mailtoUri),
                ),
                _LinkRow(
                  icon: LucideIcons.bug,
                  title: tr.errorLogsTitle,
                  onTap: () => context.push('/settings/error-logs'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AboutSpainStoryCard(tr: tr),
          ],
        ),
    );
  }
}

class _AboutSpainStoryCard extends StatelessWidget {
  const _AboutSpainStoryCard({required this.tr});

  final Tr tr;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bodyColor =
        isDark ? context.mutedText : AppColors.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2B2214),
                  context.surface,
                ]
              : [
                  const Color(0xFFFFF6E5),
                  const Color(0xFFFFFBF3),
                ],
        ),
        border: Border.all(
          color: isDark
              ? AppColors.lime.withValues(alpha: 0.22)
              : const Color(0xFFE8C878).withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.aboutSpainTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.2,
              color: context.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tr.aboutSpainParagraph1,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr.aboutSpainParagraph2,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE8D4A0).withValues(alpha: 0.7),
            ),
          ),
          Text(
            tr.aboutSpainClosing1,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr.aboutSpainClosing2,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.lime : AppColors.limeAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 66, right: 16),
                child: Divider(height: 1, color: context.divider),
              ),
          ],
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: context.primaryText),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: context.faintText),
          ],
        ),
      ),
    );
  }
}
