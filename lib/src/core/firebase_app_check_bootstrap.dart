import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Activates App Check attestation for Firebase backends (Auth, AI, Functions).
///
/// Android app id: `com.pulpo.android`.
/// iOS bundle id: `com.pulpo.app`.
///
/// - iOS **Simulator**: Apple debug provider (register token in Console).
/// - iOS **physical device**: DeviceCheck (needs Apple key in Firebase App Check).
/// - Android debug: debug provider; release: Play Integrity.
Future<void> activateFirebaseAppCheck() async {
  final appleDebug = _runningOnIosSimulator;
  final androidDebug = kDebugMode;

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        androidDebug ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider:
        appleDebug ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  if (kDebugMode) {
    final mode = appleDebug
        ? 'Apple debug (simulator)'
        : Platform.isIOS
            ? 'Apple DeviceCheck (physical device)'
            : androidDebug
                ? 'Android debug'
                : 'Play Integrity';
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      if (token != null && token.isNotEmpty) {
        if (appleDebug) {
          debugPrint(
            'App Check OK ($mode). Register this debug token in Firebase '
            'Console → App Check → Manage debug tokens:\n$token',
          );
        } else {
          debugPrint(
            'App Check OK ($mode). Token length=${token.length}. '
            'If AI still fails: Firebase Console → App Check → com.pulpo.app '
            '→ DeviceCheck (Team ID + Apple .p8 key).',
          );
        }
      } else {
        debugPrint('App Check getToken returned null ($mode). AI may fail.');
      }
    } catch (e, st) {
      final hint = appleDebug
          ? 'Fix: register debug token in Firebase Console.'
          : 'Fix: Firebase Console → App Check → com.pulpo.app → DeviceCheck '
              '(Apple Team ID VWYGQ2Z5FJ + private key .p8).';
      debugPrint(
        'App Check getToken failed ($mode) — Firebase AI will likely reject '
        'requests.\n$hint\nError: $e\n$st',
      );
    }
  }
}

bool get _runningOnIosSimulator {
  if (kIsWeb || !Platform.isIOS) return false;
  return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
      Platform.environment.containsKey('SIMULATOR_UDID');
}
