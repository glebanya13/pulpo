import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase / local data bootstrap outcome (set once in [main]).
class AppStartupState {
  const AppStartupState({
    this.firebaseReady = false,
    this.firebaseError,
    this.dataInitError,
  });

  final bool firebaseReady;
  final String? firebaseError;
  final String? dataInitError;

  bool get showFirebaseWarning => !firebaseReady && firebaseError != null;
  bool get showDataWarning => dataInitError != null;
}

final appStartupProvider = StateProvider<AppStartupState>(
  (ref) => const AppStartupState(),
);
