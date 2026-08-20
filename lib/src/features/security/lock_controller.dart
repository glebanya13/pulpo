import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/settings_service.dart';

String hashLockPin(String pin) =>
    sha256.convert(utf8.encode('pulpo:$pin')).toString();

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
  static const _kPinHash = 'lock_pin_hash';
  static const _kBio = 'lock_biometrics';
  static const _kPinLen = 'lock_pin_len';
  static const _kAuto = 'lock_autolock';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  final _auth = LocalAuthentication();

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
    state = state.copyWith(
      pinEnabled: false,
      unlocked: state.biometricsEnabled ? state.unlocked : true,
      pinLengthKnown: false,
    );
  }

  bool checkPin(String pin) {
    final stored = _prefs.getString(_kPinHash);
    if (stored == null) return false;
    final ok = stored == _hash(pin);
    if (ok) state = state.copyWith(unlocked: true);
    return ok;
  }

  Future<bool> deviceHasBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      // `canCheckBiometrics` can be true even when no biometrics are enrolled.
      // For toggle UX we want to require at least one enrolled biometric type.
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enableBiometrics() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Pulpo',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      if (!ok) return false;
      await _prefs.setBool(_kBio, true);
      state = state.copyWith(biometricsEnabled: true);
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
    if (state.autoLock) lock();
  }

  Future<bool> tryBiometrics() async {
    if (!state.biometricsEnabled) return false;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Pulpo',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
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
