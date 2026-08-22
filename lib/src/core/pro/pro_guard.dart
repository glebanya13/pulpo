import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/ai/assistant_energy.dart';
import '../../core/l10n/tr.dart';
import '../../features/auth/cloud_auth.dart';
import '../../features/pro/paywall_screen.dart';
import 'pro_controller.dart';
import 'pro_limits.dart';

Future<void> openPaywall(BuildContext context, ProGate gate) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PaywallScreen(gate: gate),
    ),
  );
}

Future<bool> requirePro(
  BuildContext context,
  WidgetRef ref,
  ProGate gate,
) async {
  if (ref.read(proControllerProvider).isPro) return true;
  await openPaywall(context, gate);
  return ref.read(proControllerProvider).isPro;
}

/// AI features require a signed-in user.
///
/// [allowFreeEnergy]: assistant chat may use the free energy quota;
/// other AI surfaces stay Pro-only.
Future<bool> requireAi(
  BuildContext context,
  WidgetRef ref, {
  bool allowFreeEnergy = false,
}) async {
  final tr = Tr.of(context);
  final isPro = ref.read(proControllerProvider).isPro;
  final signedIn = ref.read(authUserProvider).valueOrNull != null;
  if (!signedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.proSignInRequired)),
    );
    context.push('/settings/account');
    return false;
  }
  if (isPro) return true;
  if (allowFreeEnergy && ref.read(assistantEnergyProvider).hasEnergy) {
    return true;
  }
  await openPaywall(context, ProGate.ai);
  return ref.read(proControllerProvider).isPro;
}

Future<bool> requireQuota(
  BuildContext context,
  WidgetRef ref,
  ProGate gate,
  int used,
) async {
  if (ref.read(proControllerProvider).isPro) return true;
  final limit = ProLimits.freeLimit(gate);
  if (limit != null && used < limit) return true;
  await openPaywall(context, gate);
  return ref.read(proControllerProvider).isPro;
}

String quotaLabel({
  required bool isPro,
  required int used,
  required int limit,
}) =>
    isPro ? '$used' : '$used/$limit';

String formatProExpiryDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  return DateFormat('d MMMM y', locale).format(date.toLocal());
}
