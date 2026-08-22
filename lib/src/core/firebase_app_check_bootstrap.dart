import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Activates App Check attestation for Firebase backends (Auth, AI, Functions).
///
/// Android app id: `com.pulpo.android`.
/// iOS bundle id: `com.pulpo.app`.
///
/// Debug / Simulator: Apple & Android **debug** providers — copy the printed
/// token into Firebase Console → App Check → Manage debug tokens.
/// Release: Play Integrity (Android) and Device Check (iOS). Register the apps
/// under App Check before enforcing AI Logic.
Future<void> activateFirebaseAppCheck() async {
  final useDebug = kDebugMode || _runningOnIosSimulator;

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        useDebug ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: useDebug ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  if (kDebugMode) {
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      if (token != null && token.isNotEmpty) {
        debugPrint(
          'App Check OK (debug). Register this token in Firebase Console → '
          'App Check → Manage debug tokens if AI still fails:\n$token',
        );
      } else {
        debugPrint(
          'App Check getToken returned null. AI may fail until a debug token '
          'is registered in Firebase Console.',
        );
      }
    } catch (e, st) {
      debugPrint(
        'App Check getToken failed — Firebase AI will likely reject requests.\n'
        'Fix: Firebase Console → App Check → Apps → Manage debug tokens, '
        'and enable -FIRDebugEnabled in the Xcode scheme if needed.\n'
        'Error: $e\n$st',
      );
    }
  }
}

bool get _runningOnIosSimulator {
  if (kIsWeb || !Platform.isIOS) return false;
  return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
      Platform.environment.containsKey('SIMULATOR_UDID');
}
