import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/l10n/tr.dart';
import '../../core/promo/home_ad.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/home_ad_card.dart';
import '../../widgets/common.dart';
import '../../widgets/reset_scroll_when_obscured.dart';
import 'monthly_calendar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final pad = AppSpacing.tabPagePadding(context);
    final ad = ref.watch(visibleHomeAdProvider);

    return ResetScrollWhenObscured(
      tabPath: '/',
      // Keep scroll when opening a tx / sheet and coming back.
      preserveScrollOnPush: true,
      builder: (context, scroll) {
        return MonthlyCalendar(
          scrollController: scroll,
          padding: pad,
          pageHeader: ScreenTitlePill(
            title: AppInfo.displayName,
            subtitle: tr.dashboardSubtitle,
            leading: BrandLogo(size: 34, plate: false),
            large: true,
            expand: true,
            trailing: const HeaderSupportActions(dense: true),
          ),
          // Month chrome (Day / Calendar / Month) is the home basis —
          // no total-balance card. Add flows stay on the FAB.
          leading: [
            if (ad != null) ...[
              HomeAdCard(ad: ad),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
