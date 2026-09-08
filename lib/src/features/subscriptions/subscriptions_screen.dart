import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/utils/money_format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/repositories/settings_service.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final subsAsync = ref.watch(subscriptionsProvider);
    final subs = subsAsync.valueOrNull ?? const [];
    final active = subs.where((s) => !s.isPaused).toList();
    final used = active.length;
    final isPro = ref.watch(proControllerProvider).isPro;
    final currency = ref.watch(settingsControllerProvider).baseCurrency;

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
              first: tr.subscriptions,
              subtitle: quotaLabel(
                  isPro: isPro,
                  used: active.length,
                  limit: ProLimits.subscriptions),
              onBack: () => context.pop(),
              action: RoundIconButton(
                icon: LucideIcons.plus,
                onTap: () => _openAdd(context, ref, used),
              ),
            ),
        children: [
            AsyncValuesGate(
              values: [subsAsync],
              onRetry: () => ref.invalidate(subscriptionsProvider),
              child: Builder(
                builder: (context) {
                  final loaded = subsAsync.requireValue;
                  final activeLoaded =
                      loaded.where((s) => !s.isPaused).toList();
                  final monthly = _monthlyTotal(activeLoaded);
                  final yearly = monthly * 12;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TotalCard(
                              label: tr.perMonth,
                              value: monthly,
                              currency: currency,
                              accent: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TotalCard(
                              label: tr.perYear,
                              value: yearly,
                              currency: currency,
                              accent: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (loaded.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: EmptyState(
                            icon: LucideIcons.tv,
                            title: tr.subsEmptyTitle,
                            description: tr.subsEmptyDesc,
                            background: AppColors.bgFood,
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            tr.nextPaymentLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.mutedText,
                            ),
                          ),
                        ),
                        if (activeLoaded.isNotEmpty)
                          _SubCard(
                            sub: activeLoaded.first,
                            highlighted: true,
                          ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            tr.allSubscriptions,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.mutedText,
                            ),
                          ),
                        ),
                        for (final s in loaded)
                          _SubCard(sub: s, highlighted: false),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  double _monthlyTotal(List<db.Subscription> subs) {
    var m = 0.0;
    for (final s in subs) {
      if (s.cycle == 'yearly') {
        m += s.amount / 12;
      } else {
        m += s.amount;
      }
    }
    return m;
  }

  Future<void> _openAdd(
    BuildContext context,
    WidgetRef ref,
    int used,
  ) async {
    if (!await requireQuota(context, ref, ProGate.subscriptions, used)) {
      return;
    }
    if (!context.mounted) return;
    context.push('/subscriptions/new');
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.currency,
    required this.accent,
  });
  final String label;
  final double value;
  final String currency;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = context.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent
            ? accentColor.withValues(alpha: 0.1)
            : context.surface,
        border: accent
            ? Border.all(color: accentColor.withValues(alpha: 0.25))
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: context.mutedText, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(value, currency),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent ? accentColor : context.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubCard extends ConsumerWidget {
  const _SubCard({required this.sub, required this.highlighted});
  final db.Subscription sub;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final daysUntil = sub.nextPayment.difference(DateTime.now()).inDays;

    final accentColor = context.accent;
    return Pressable(
      onTap: () => context.push('/subscriptions/${sub.id}/edit'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? accentColor.withValues(alpha: 0.08)
            : context.surface,
        border: highlighted
            ? Border.all(color: accentColor.withValues(alpha: 0.25))
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Color(sub.logoColor),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              sub.logoLetter.isNotEmpty
                  ? sub.logoLetter
                  : sub.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: TextStyle(
                      color: context.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        color: context.mutedText, fontSize: 11),
                    children: [
                      TextSpan(
                          text:
                              '${sub.cycle == 'yearly' ? tr.yearlyLabel : tr.monthlyLabel} · '),
                      TextSpan(
                        text: highlighted && daysUntil <= 7
                            ? tr.inDays(daysUntil)
                            : DateFormat('d MMM', locale)
                                .format(sub.nextPayment),
                        style: highlighted
                            ? TextStyle(color: accentColor)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(sub.amount, sub.currency),
            style: TextStyle(
              color: context.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
