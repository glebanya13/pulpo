import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/settings_service.dart';

String hashLockPin(String pin) =>
    sha256.convert(utf8.encode('pulpo:$pin')).toString();

/// iOS often returns an empty enrolled list even when Face ID works.
@visibleForTesting
bool biometricsLikelyAvailable({
  required bool canCheck,
  required bool deviceSupported,
  required List<BiometricType> enrolled,
}) {
  if (enrolled.isNotEmpty) return true;
  // Prefer canCheck — deviceSupported alone is true for passcode-only devices
  // and then biometricOnly / Face ID prompts fail.
  if (canCheck) return true;
  return false;
}

@visibleForTesting
bool shouldAutoLockOnPause({
  required bool autoLock,
  required bool hasLock,
  required bool authInProgress,
  DateTime? ignorePauseUntil,
  DateTime? now,
}) {
  if (authInProgress) return false;
  final until = ignorePauseUntil;
  if (until != null && (now ?? DateTime.now()).isBefore(until)) {
    return false;
  }
  return autoLock && hasLock;
}

class LockState {
  const LockState({
    required this.pinEnabled,
    required this.biometricsEnabled,
    required this.autoLock,
    required this.unlocked,
    required this.pinLength,
    required this.pinLengthKnown,
  });

  final bool pinEnabled;
  final bool biometricsEnabled;
  final bool autoLock;
  final bool unlocked;
  final int pinLength;
  final bool pinLengthKnown;

  bool get hasLock => pinEnabled || biometricsEnabled;

  bool get needsLock => hasLock && !unlocked;

  LockState copyWith({
    bool? pinEnabled,
    bool? biometricsEnabled,
    bool? autoLock,
    bool? unlocked,
    int? pinLength,
    bool? pinLengthKnown,
  }) {
    return LockState(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      autoLock: autoLock ?? this.autoLock,
      unlocked: unlocked ?? this.unlocked,
      pinLength: pinLength ?? this.pinLength,
      pinLengthKnown: pinLengthKnown ?? this.pinLengthKnown,
    );
  }
}

class LockController extends Notifier<LockState> {
  LockController({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  static const _kPinHash = 'lock_pin_hash';
  static const _kBio = 'lock_biometrics';
  static const _kPinLen = 'lock_pin_len';
  static const _kAuto = 'lock_autolock';

  /// Face ID dismissal fires lifecycle pause after auth returns — ignore briefly.
  static const _pauseGrace = Duration(seconds: 3);

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  final LocalAuthentication _auth;
  var _authInProgress = false;
  DateTime? _ignorePauseUntil;

  @visibleForTesting
  bool get authInProgress => _authInProgress;

  @override
  LockState build() {
    final hash = _prefs.getString(_kPinHash);
    final pinOn = hash != null && hash.isNotEmpty;
    final bioOn = _prefs.getBool(_kBio) ?? false;
    return LockState(
      pinEnabled: pinOn,
      biometricsEnabled: bioOn,
      autoLock: _prefs.getBool(_kAuto) ?? true,
      unlocked: !(pinOn || bioOn),
      pinLength: _prefs.getInt(_kPinLen) ?? 4,
      pinLengthKnown: _prefs.containsKey(_kPinLen),
    );
  }

  String _hash(String pin) => hashLockPin(pin);

  Future<void> setPin(String pin) async {
    await _prefs.setString(_kPinHash, _hash(pin));
    await _prefs.setInt(_kPinLen, pin.length);
    state = state.copyWith(
      pinEnabled: true,
      unlocked: true,
      pinLength: pin.length,
      pinLengthKnown: true,
    );
  }

  Future<void> clearPin() async {
    await _prefs.remove(_kPinHash);
    await _prefs.remove(_kPinLen);
    // PIN is the escape hatch for Face ID failure — drop biometrics too.
    await _prefs.setBool(_kBio, false);
    state = state.copyWith(
      pinEnabled: false,
      biometricsEnabled: false,
      unlocked: true,
      pinLengthKnown: false,
    );
  }

  bool checkPin(String pin) {
    final stored = _prefs.getString(_kPinHash);
    if (stored == null) return false;
    final ok = stored == _hash(pin);
    if (ok) {
      // Persist length so UI shows the right number of dots next time.
      if (!state.pinLengthKnown) {
        _prefs.setInt(_kPinLen, pin.length);
      }
      state = state.copyWith(
        unlocked: true,
        pinLength: pin.length,
        pinLengthKnown: true,
      );
    }
    return ok;
  }

  Future<bool> deviceHasBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      final types = await _auth.getAvailableBiometrics();
      debugPrint(
        'biometrics: canCheck=$canCheck supported=$supported types=$types',
      );
      return biometricsLikelyAvailable(
        canCheck: canCheck,
        deviceSupported: supported,
        enrolled: types,
      );
    } catch (e, st) {
      debugPrint('deviceHasBiometrics: $e\n$st');
      return false;
    }
  }

  Future<bool> _authenticate({
    required bool sticky,
    String localizedReason = 'Monedero',
    bool allowDeviceCredential = false,
  }) async {
    if (_authInProgress) return false;
    _authInProgress = true;
    // Ignore pause events that Face ID itself triggers.
    _ignorePauseUntil = DateTime.now().add(_pauseGrace);
    try {
      try {
        await _auth.stopAuthentication();
      } catch (_) {}

      // With a PIN set: Face ID only (PIN pad is the fallback).
      // Bio-only legacy installs: allow device passcode so users aren't locked out.
      final ok = await _auth.authenticate(
        localizedReason: localizedReason,
        authMessages: <AuthMessages>[
          IOSAuthMessages(
            localizedFallbackTitle: allowDeviceCredential ? 'Passcode' : '',
            lockOut: localizedReason,
          ),
          const AndroidAuthMessages(),
        ],
        options: AuthenticationOptions(
          biometricOnly: !allowDeviceCredential,
          stickyAuth: sticky,
          sensitiveTransaction: false,
          useErrorDialogs: false,
        ),
      );
      if (ok) {
        _ignorePauseUntil = DateTime.now().add(_pauseGrace);
      }
      return ok;
    } on PlatformException catch (e) {
      debugPrint('local_auth: ${e.code} ${e.message}');
      return false;
    } finally {
      _authInProgress = false;
    }
  }

  Future<bool> enableBiometrics({String localizedReason = 'Monedero'}) async {
    if (!state.pinEnabled) {
      debugPrint('enableBiometrics: PIN required');
      return false;
    }
    try {
      final ok = await _authenticate(
        sticky: true,
        localizedReason: localizedReason,
      );
      if (!ok) return false;
      await _prefs.setBool(_kBio, true);
      state = state.copyWith(biometricsEnabled: true, unlocked: true);
      return true;
    } catch (e, st) {
      debugPrint('enable biometrics: $e\n$st');
      return false;
    }
  }

  Future<void> setBiometrics(bool v) async {
    if (v) {
      await enableBiometrics();
      return;
    }
    await _prefs.setBool(_kBio, false);
    state = state.copyWith(
      biometricsEnabled: false,
      unlocked: state.pinEnabled ? state.unlocked : true,
    );
  }

  Future<void> setAutoLock(bool v) async {
    await _prefs.setBool(_kAuto, v);
    state = state.copyWith(autoLock: v);
  }

  void lock() {
    if (state.hasLock) state = state.copyWith(unlocked: false);
  }

  void onAppPaused() {
    if (shouldAutoLockOnPause(
      autoLock: state.autoLock,
      hasLock: state.hasLock,
      authInProgress: _authInProgress,
      ignorePauseUntil: _ignorePauseUntil,
    )) {
      lock();
    }
  }

  Future<bool> tryBiometrics({String localizedReason = 'Monedero'}) async {
    if (!state.biometricsEnabled || !state.needsLock) return false;
    if (_authInProgress) return false;
    try {
      final ok = await _authenticate(
        sticky: true,
        localizedReason: localizedReason,
        // Legacy bio-without-PIN: device passcode escape hatch.
        allowDeviceCredential: !state.pinEnabled,
      );
      if (ok) state = state.copyWith(unlocked: true);
      return ok;
    } catch (e, st) {
      debugPrint('biometrics: $e\n$st');
      return false;
    }
  }
}

final lockControllerProvider =
    NotifierProvider<LockController, LockState>(LockController.new);
