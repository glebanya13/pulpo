import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Activates App Check attestation for Firebase backends (Auth, AI, Functions).
///
/// Android app id: `com.pulpo.android`.
/// iOS bundle id: `com.pulpo.app`.
///
/// **Debug builds** use the debug provider on every device (simulator + phone).
/// Copy the printed token into Firebase Console → App Check → Manage debug tokens.
///
/// **Release / profile** use DeviceCheck (iOS) and Play Integrity (Android).
/// Those providers must be registered in the Firebase Console before AI Logic
/// enforcement will accept production traffic.
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
        debugPrint(
          '═══════════════════════════════════════════════════════════\n'
          'App Check DEBUG token (register in Firebase Console →\n'
          'App Check → Apps → com.pulpo.app / com.pulpo.android →\n'
          'Manage debug tokens). AI will fail until this is saved:\n'
          '$token\n'
          '═══════════════════════════════════════════════════════════',
        );
      } else {
        debugPrint(
          'App Check getToken returned null. AI will fail until a debug '
          'token is available (add -FIRDebugEnabled to the Xcode scheme).',
        );
      }
    } catch (e, st) {
      debugPrint(
        'App Check getToken failed — Firebase AI will reject requests.\n'
        'Fix: Firebase Console → App Check → Manage debug tokens.\n'
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
