import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/settings_service.dart';

/// Free assistant quota: 100 energy ≈ 3 minutes of active use.
class AssistantEnergy {
  const AssistantEnergy._();

  static const maxUnits = 100;
  static const freeQuota = Duration(minutes: 3);

  static int unitsFromMs(int remainingMs) {
    if (remainingMs <= 0) return 0;
    final q = freeQuota.inMilliseconds;
    return ((remainingMs / q) * maxUnits).ceil().clamp(1, maxUnits);
  }
}

class AssistantEnergyState {
  const AssistantEnergyState({required this.remainingMs});

  final int remainingMs;

  int get units => AssistantEnergy.unitsFromMs(remainingMs);

  bool get hasEnergy => remainingMs > 0;
}

class AssistantEnergyController extends Notifier<AssistantEnergyState> {
  static const _key = 'assistant_energy_remaining_ms';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AssistantEnergyState build() {
    final stored = _prefs.getInt(_key);
    if (stored == null) {
      final full = AssistantEnergy.freeQuota.inMilliseconds;
      Future.microtask(() => _prefs.setInt(_key, full));
      return AssistantEnergyState(remainingMs: full);
    }
    return AssistantEnergyState(
      remainingMs: stored.clamp(0, AssistantEnergy.freeQuota.inMilliseconds),
    );
  }

  Future<void> _persist(int ms) async {
    await _prefs.setInt(_key, ms);
  }

  /// Consumes wall-clock usage. Returns remaining ms after consume.
  Future<int> consumeMs(int ms) async {
    if (ms <= 0) return state.remainingMs;
    final next =
        (state.remainingMs - ms).clamp(0, AssistantEnergy.freeQuota.inMilliseconds);
    if (next == state.remainingMs) return next;
    state = AssistantEnergyState(remainingMs: next);
    await _persist(next);
    return next;
  }

  Future<void> resetForDebug() async {
    final full = AssistantEnergy.freeQuota.inMilliseconds;
    state = AssistantEnergyState(remainingMs: full);
    await _persist(full);
  }
}

final assistantEnergyProvider =
    NotifierProvider<AssistantEnergyController, AssistantEnergyState>(
  AssistantEnergyController.new,
);
