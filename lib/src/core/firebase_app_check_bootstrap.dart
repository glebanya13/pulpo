import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Activates App Check attestation for Firebase backends (Auth, AI, Functions).
///
/// Android app id: `com.pulpo.android`.
/// iOS bundle id: `com.pulpo.app`.
///
/// **Debug builds** use the debug provider on every device (simulator + phone).
/// Copy the native UUID from Xcode/sim logs (`Firebase App Check Debug Token:`)
/// into Firebase Console → App Check → Apps → com.pulpo.app → Manage debug tokens.
/// Do **not** paste the JWT from `getToken()` — only the UUID.
///
/// **Release / profile** use DeviceCheck (iOS) and Play Integrity (Android).
Future<void> activateFirebaseAppCheck() async {
  final useDebug = kDebugMode;

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        useDebug ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider:
        useDebug ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  if (kDebugMode) {
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      if (token != null && token.isNotEmpty) {
        debugPrint('App Check OK (debug provider).');
      } else {
        debugPrint(
          'App Check getToken returned null. AI will fail until a debug '
          'token is available (add -FIRDebugEnabled to the Xcode scheme).',
        );
      }
    } catch (e, st) {
      debugPrint(
        'App Check getToken failed — Firebase AI will reject requests.\n'
        'Fix: Firebase Console → App Check → Manage debug tokens '
        '(register the UUID from "Firebase App Check Debug Token" logs).\n'
        'Error: $e\n$st',
      );
    }
  } else if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    debugPrint(
      'App Check production provider active '
      '(${Platform.isIOS ? 'DeviceCheck' : 'Play Integrity'}).',
    );
  }
}
