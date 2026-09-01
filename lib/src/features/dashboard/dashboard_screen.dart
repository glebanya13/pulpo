import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/pressable.dart';
import '../../widgets/common.dart';
import '../../core/utils/money_format.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/reset_scroll_when_obscured.dart';
import 'monthly_calendar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final total = ref.watch(totalBalanceProvider);
    final currency = settings.baseCurrency;
    final fxApprox = ref.watch(fxApproximateProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final txsAsync = ref.watch(allTransactionsProvider);

    void retryBalance() {
      ref.invalidate(accountsProvider);
      ref.invalidate(allTransactionsProvider);
    }

    return ResetScrollWhenObscured(
      tabPath: '/',
      builder: (context, scroll) {
        final pad = AppSpacing.tabPagePadding(context);
        return StickyScrollPage(
          useSafeArea: false,
          controller: scroll,
          padding: pad,
          headerGap: 0,
          headerBottomPadding: 10,
          header: ScreenTitlePill(
            title: settings.userName,
            eyebrow: tr.greetingForHour(DateTime.now().hour),
            large: true,
            expand: true,
            trailing: const HeaderSupportActions(
              dense: true,
              accountIconOnly: true,
            ),
          ),
          children: [
            AsyncValuesGate(
              values: [accountsAsync, txsAsync],
              onRetry: retryBalance,
              child: _BalanceActionCard(
                total: total,
                currency: currency,
                fxApproximate: fxApprox.isNotEmpty,
              ),
            ),
            const SizedBox(height: 12),
            const MonthlyCalendar(),
          ],
        );
      },
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onDark = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final chipBg = onDark
        ? Colors.white.withValues(alpha: 0.12)
        : context.surface;
    final iconColor = onDark ? Colors.white : context.primaryText;

    return Expanded(
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          button: true,
          child: Pressable(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceActionCard extends StatelessWidget {
  const _BalanceActionCard({
    required this.total,
    required this.currency,
    this.fxApproximate = false,
  });

  final double total;
  final String currency;
  final bool fxApproximate;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: context.emphasized,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.emphasizedBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr.totalBalance,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(total, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          if (fxApproximate) ...[
            const SizedBox(height: 6),
            Text(
              tr.fxApproximateBalance,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickChip(
                icon: LucideIcons.plus,
                label: tr.income,
                onDark: true,
                onTap: () => context.push('/add?type=income'),
              ),
              const SizedBox(width: 6),
              _QuickChip(
                icon: LucideIcons.minus,
                label: tr.expense,
                onDark: true,
                onTap: () => context.push('/add?type=expense'),
              ),
              const SizedBox(width: 6),
              _QuickChip(
                icon: LucideIcons.arrowLeftRight,
                label: tr.transferBetweenAccounts,
                onDark: true,
                onTap: () => context.push('/add?type=transfer'),
              ),
              const SizedBox(width: 6),
              _QuickChip(
                icon: LucideIcons.send,
                label: tr.transferExternal,
                onDark: true,
                onTap: () => context.push('/add?type=expense&mode=external'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
