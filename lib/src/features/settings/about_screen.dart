import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/app_info.dart';
import '../../core/l10n/tr.dart';
import '../../core/open_link.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(first: tr.about, onBack: () => context.pop()),
            const SizedBox(height: 24),
            Center(
              child: Image.asset(
                'assets/logo.png',
                height: 72,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Pulpo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
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
                  icon: LucideIcons.mail,
                  title: AppInfo.supportEmail,
                  onTap: () => openAppLink(context, AppInfo.mailtoUri),
                ),
              ],
            ),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppColors.ink),
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
