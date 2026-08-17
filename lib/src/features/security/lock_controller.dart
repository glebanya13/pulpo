import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/settings_service.dart';

class LockState {
  const LockState({
    required this.pinEnabled,
    required this.biometricsEnabled,
    required this.autoLock,
    required this.unlocked,
  });

  final bool pinEnabled;
  final bool biometricsEnabled;
  final bool autoLock;
  final bool unlocked;

  bool get needsLock => pinEnabled && !unlocked;

  LockState copyWith({
    bool? pinEnabled,
    bool? biometricsEnabled,
    bool? autoLock,
    bool? unlocked,
  }) {
    return LockState(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      autoLock: autoLock ?? this.autoLock,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}

class LockController extends Notifier<LockState> {
  static const _kPinHash = 'lock_pin_hash';
  static const _kBio = 'lock_biometrics';
  static const _kAuto = 'lock_autolock';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  final _auth = LocalAuthentication();

  @override
  LockState build() {
    final hash = _prefs.getString(_kPinHash);
    return LockState(
      pinEnabled: hash != null && hash.isNotEmpty,
      biometricsEnabled: _prefs.getBool(_kBio) ?? false,
      autoLock: _prefs.getBool(_kAuto) ?? true,
      unlocked: hash == null || hash.isEmpty,
    );
  }

  String _hash(String pin) => sha256.convert(utf8.encode('pulpo:$pin')).toString();

  Future<void> setPin(String pin) async {
    await _prefs.setString(_kPinHash, _hash(pin));
    state = state.copyWith(pinEnabled: true, unlocked: true);
  }

  Future<void> clearPin() async {
    await _prefs.remove(_kPinHash);
    await _prefs.setBool(_kBio, false);
    state = state.copyWith(
      pinEnabled: false,
      biometricsEnabled: false,
      unlocked: true,
    );
  }

  bool checkPin(String pin) {
    final stored = _prefs.getString(_kPinHash);
    if (stored == null) return false;
    final ok = stored == _hash(pin);
    if (ok) state = state.copyWith(unlocked: true);
    return ok;
  }

  Future<void> setBiometrics(bool v) async {
    await _prefs.setBool(_kBio, v);
    state = state.copyWith(biometricsEnabled: v);
  }

  Future<void> setAutoLock(bool v) async {
    await _prefs.setBool(_kAuto, v);
    state = state.copyWith(autoLock: v);
  }

  void lock() {
    if (state.pinEnabled) state = state.copyWith(unlocked: false);
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
