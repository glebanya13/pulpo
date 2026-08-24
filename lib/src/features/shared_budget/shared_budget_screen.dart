import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../features/auth/cloud_auth.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';
import 'household_service.dart';

class SharedBudgetScreen extends ConsumerStatefulWidget {
  const SharedBudgetScreen({super.key});

  @override
  ConsumerState<SharedBudgetScreen> createState() => _SharedBudgetScreenState();
}

class _SharedBudgetScreenState extends ConsumerState<SharedBudgetScreen> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final signedIn = ref.watch(authUserProvider).valueOrNull != null;
    final householdId = ref.watch(householdIdProvider).valueOrNull;
    final household = ref.watch(householdSnapshotProvider).valueOrNull;
    final entries = ref.watch(sharedEntriesProvider).valueOrNull ?? const [];
    final currency = ref.watch(settingsControllerProvider).baseCurrency;

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
              first: tr.sharedBudgetTitle,
              onBack: () => context.pop(),
            ),
        headerGap: 8,
        children: [
            Text(
              tr.sharedBudgetSubtitle,
              style: TextStyle(fontSize: 14, color: context.mutedText),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 20),
            if (!signedIn)
              _SignInCard(onTap: () => context.push('/settings/account'))
            else if (householdId == null || household == null)
              _SetupCard(
                codeCtrl: _codeCtrl,
                busy: _busy,
                showPro: !ref.watch(proControllerProvider).isPro,
                onCreate: () => _run(() async {
                  if (!await requirePro(context, ref, ProGate.sharedBudget)) {
                    return;
                  }
                  await ref.read(householdServiceProvider).createHousehold();
                }),
                onJoin: () => _run(() async {
                  if (!await requirePro(context, ref, ProGate.sharedBudget)) {
                    return;
                  }
                  await ref
                      .read(householdServiceProvider)
                      .joinHousehold(_codeCtrl.text);
                }),
              )
            else
              _ActiveHouseholdView(
                household: household,
                entries: entries,
                currency: currency,
                busy: _busy,
                onSync: () => _syncExpenses(household.id),
                onLeave: () => _run(() async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(tr.sharedBudgetLeaveTitle),
                      content: Text(tr.sharedBudgetLeaveBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(tr.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(tr.sharedBudgetLeave),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  await ref
                      .read(householdServiceProvider)
                      .leaveHousehold(household.id);
                }),
                onCopyCode: () {
                  Clipboard.setData(
                    ClipboardData(text: household.inviteCode),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr.sharedBudgetCodeCopied)),
                  );
                },
              ),
          ],
        ),
    );
  }

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      if (!mounted) return;
      final tr = Tr.of(context);
      final msg = switch ('$e') {
        _ when '$e'.contains('invite_not_found') => tr.sharedBudgetInvalidCode,
        _ when '$e'.contains('household_full') => tr.sharedBudgetFull,
        _ when '$e'.contains('already_in_household') =>
          tr.sharedBudgetAlreadyJoined,
        _ => tr.errorTitle,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncExpenses(String householdId) async {
    await _run(() async {
      if (!await requirePro(context, ref, ProGate.sharedBudget)) return;
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      final txs = ref.read(allTransactionsProvider).valueOrNull ?? const [];
      final cats = ref.read(categoriesProvider).valueOrNull ?? const [];
      final n = await ref.read(householdServiceProvider).syncLocalExpenses(
            householdId: householdId,
            txs: txs,
            categories: cats,
            monthStart: start,
            monthEnd: end,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.of(context).sharedBudgetSynced(n))),
      );
    });
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr.sharedBudgetSignIn, style: TextStyle(color: context.mutedText)),
          const SizedBox(height: 12),
          ScaledElevatedButton(onPressed: onTap, child: Text(tr.signIn)),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.codeCtrl,
    required this.busy,
    required this.onCreate,
    required this.onJoin,
    this.showPro = false,
  });

  final TextEditingController codeCtrl;
  final bool busy;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final bool showPro;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScaledFilledButton(
          onPressed: busy ? null : onCreate,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr.sharedBudgetCreate),
              if (showPro) ...[
                const SizedBox(width: 8),
                const ProBadge(dense: true, onAccent: true),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(tr.sharedBudgetJoinHint,
            style: TextStyle(fontSize: 13, color: context.mutedText)),
        const SizedBox(height: 10),
        TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: tr.sharedBudgetInviteCode,
            hintText: 'ABC123',
          ),
        ),
        const SizedBox(height: 12),
        ScaledOutlinedButton(
          onPressed: busy ? null : onJoin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr.sharedBudgetJoin),
              if (showPro) ...[
                const SizedBox(width: 8),
                const ProBadge(dense: true),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveHouseholdView extends ConsumerWidget {
  const _ActiveHouseholdView({
    required this.household,
    required this.entries,
    required this.currency,
    required this.busy,
    required this.onSync,
    required this.onLeave,
    required this.onCopyCode,
  });

  final HouseholdSnapshot household;
  final List<SharedEntry> entries;
  final String currency;
  final bool busy;
  final VoidCallback onSync;
  final VoidCallback onLeave;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return const SizedBox.shrink();

    final partnerUid = household.memberIds.where((id) => id != myUid).firstOrNull;
    final me = household.member(myUid);
    final partner =
        partnerUid == null ? null : household.member(partnerUid);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final settlement = HouseholdService.settlement(
      entries: entries,
      myUid: myUid,
      partnerUid: partnerUid ?? '',
      currency: currency,
      monthStart: monthStart,
      monthEnd: monthEnd,
    );

    final myCats = HouseholdService.topCategoriesForUser(entries, myUid);
    final partnerCats = partnerUid == null
        ? const <CategorySpend>[]
        : HouseholdService.topCategoriesForUser(entries, partnerUid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.sharedBudgetInviteCode,
                        style: TextStyle(
                            fontSize: 12, color: context.mutedText)),
                    const SizedBox(height: 4),
                    Text(
                      household.inviteCode,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: context.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Pressable(
                onTap: onCopyCode,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.copy, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MemberCard(
                name: me?.displayName ?? tr.youLabel,
                spends: myCats,
                currency: currency,
                accent: AppColors.lime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MemberCard(
                name: partner?.displayName ?? tr.sharedBudgetWaitingPartner,
                spends: partnerCats,
                currency: currency,
                accent: const Color(0xFF7C6CFF),
                placeholder: partner == null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.emphasized,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            settlement.even
                ? tr.sharedBudgetEven
                : settlement.partnerOwesYou > 0
                    ? tr.sharedBudgetPartnerOwes(
                        formatMoney(settlement.partnerOwesYou, currency))
                    : tr.sharedBudgetYouOwe(
                        formatMoney(settlement.youOwe, currency)),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ScaledFilledButton(
          onPressed: busy ? null : onSync,
          child: Text(tr.sharedBudgetSyncExpenses),
        ),
        const SizedBox(height: 8),
        ScaledOutlinedButton(
          onPressed: busy ? null : onLeave,
          child: Text(tr.sharedBudgetLeave),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.name,
    required this.spends,
    required this.currency,
    required this.accent,
    this.placeholder = false,
  });

  final String name;
  final List<CategorySpend> spends;
  final String currency;
  final Color accent;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withValues(alpha: 0.35),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (placeholder)
            Text(
              Tr.of(context).sharedBudgetWaitingPartner,
              style: TextStyle(fontSize: 12, color: context.mutedText),
            )
          else if (spends.isEmpty)
            Text(
              Tr.of(context).empty,
              style: TextStyle(fontSize: 12, color: context.mutedText),
            )
          else
            for (final s in spends)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ColorWellIcon(
                      color: Color(s.color),
                      icon: lucideByKey(s.icon),
                      size: 28,
                      iconSize: 13,
                      radius: 8,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Tr.of(context).categoryName(s.name),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.primaryText,
                        ),
                      ),
                    ),
                    Text(
                      formatMoney(s.amount, currency),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
