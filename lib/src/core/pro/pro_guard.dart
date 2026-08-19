import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
