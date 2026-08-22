import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Activates App Check attestation for Firebase backends (Auth, AI, Functions).
///
/// Android app id: [AppInfo.androidBundleId] (`com.pulpo.android`).
/// iOS bundle id: [AppInfo.bundleId] (`com.pulpo.app`) — register both in
/// Firebase Console → App Check with the correct SHA-256 / App Attest keys.
///
/// Debug builds use debug providers — register tokens in Firebase Console →
/// App Check → Manage debug tokens. Release uses Play Integrity (Android) and
/// App Attest with Device Check fallback (iOS).
Future<void> activateFirebaseAppCheck() async {
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttestWithDeviceCheckFallback,
  );

  if (kDebugMode) {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      if (token != null) {
        debugPrint(
          'App Check debug token (register in Firebase Console → App Check): $token',
        );
      }
    } catch (e, st) {
      debugPrint('App Check getToken: $e\n$st');
    }
  }
}
