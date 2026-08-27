import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/scheduled_posting.dart';
import 'lock_controller.dart';
import 'pin_pad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with WidgetsBindingObserver {
  String _pin = '';
  String? _error;
  var _promptGeneration = 0;
  var _promptInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleBiometricPrompt();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleBiometricPrompt();
    }
  }

  void _scheduleBiometricPrompt() {
    final gen = ++_promptGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || gen != _promptGeneration || _promptInFlight) return;
      final lock = ref.read(lockControllerProvider);
      if (!lock.biometricsEnabled || !lock.needsLock) return;

      // Face ID fails with notInteractive if LAContext starts while inactive.
      final ready = await _waitUntilResumed();
      if (!ready || !mounted || gen != _promptGeneration) return;
      // Extra settle after resume paint / transition.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || gen != _promptGeneration) return;
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }

      final still = ref.read(lockControllerProvider);
      if (!still.biometricsEnabled || !still.needsLock) return;

      _promptInFlight = true;
      try {
        final tr = Tr.of(context);
        await ref.read(lockControllerProvider.notifier).tryBiometrics(
              localizedReason: tr.biometricLockHint,
            );
      } finally {
        _promptInFlight = false;
      }
    });
  }

  /// Returns false if the app never reached [AppLifecycleState.resumed].
  Future<bool> _waitUntilResumed() async {
    for (var i = 0; i < 40; i++) {
      if (!mounted) return false;
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return mounted &&
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  void _onPin(String next) {
    final lock = ref.read(lockControllerProvider);
    final knownLen = lock.pinLength;
    final hasStoredLen = lock.pinLengthKnown;
    setState(() {
      _pin = next;
      _error = null;
    });
    if (hasStoredLen) {
      if (next.length == knownLen) _tryPin(next, showError: true);
      return;
    }
    if (next.length >= 4) {
      final ok = ref.read(lockControllerProvider.notifier).checkPin(next);
      if (ok) return;
      if (next.length >= 6) {
        setState(() {
          _error = Tr.of(context).pinWrong;
          _pin = '';
        });
      }
    }
  }

  void _tryPin(String pin, {required bool showError}) {
    final ok = ref.read(lockControllerProvider.notifier).checkPin(pin);
    if (!ok && showError) {
      setState(() {
        _error = Tr.of(context).pinWrong;
        _pin = '';
      });
    }
  }

  Future<void> _retryBiometrics() async {
    if (_promptInFlight) return;
    final ready = await _waitUntilResumed();
    if (!ready || !mounted) return;
    final tr = Tr.of(context);
    await ref.read(lockControllerProvider.notifier).tryBiometrics(
          localizedReason: tr.biometricLockHint,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final lock = ref.watch(lockControllerProvider);
    final showPin = lock.pinEnabled;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: showPin
              ? _PinLockBody(
                  title: tr.enterPin,
                  error: _error,
                  pinLength: lock.pinLengthKnown ? lock.pinLength : 6,
                  pin: _pin,
                  onPinChanged: _onPin,
                  showBiometrics: lock.biometricsEnabled,
                  onBiometrics: _retryBiometrics,
                  biometricsLabel: tr.unlock,
                )
              : _BioLockBody(
                  title: tr.unlock,
                  hint: tr.unlockBiometricHint,
                  error: _error,
                  onUnlock: _retryBiometrics,
                  unlockLabel: tr.unlock,
                ),
        ),
      ),
    );
  }
}

class _BioLockBody extends StatelessWidget {
  const _BioLockBody({
    required this.title,
    required this.hint,
    required this.error,
    required this.onUnlock,
    required this.unlockLabel,
  });

  final String title;
  final String hint;
  final String? error;
  final VoidCallback onUnlock;
  final String unlockLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        const BrandLogo(size: 88, plate: false, onDarkSurface: true),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 36),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onUnlock,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.lime.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.fingerprint,
                size: 40,
                color: AppColors.lime,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          unlockLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

class _PinLockBody extends StatelessWidget {
  const _PinLockBody({
    required this.title,
    required this.error,
    required this.pinLength,
    required this.pin,
    required this.onPinChanged,
    required this.showBiometrics,
    required this.onBiometrics,
    required this.biometricsLabel,
  });

  final String title;
  final String? error;
  final int pinLength;
  final String pin;
  final ValueChanged<String> onPinChanged;
  final bool showBiometrics;
  final VoidCallback onBiometrics;
  final String biometricsLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 28),
        const BrandLogo(size: 64, plate: false, onDarkSurface: true),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const Spacer(),
        PinPad(
          length: pinLength,
          value: pin,
          onChanged: onPinChanged,
          dark: true,
        ),
        const Spacer(),
        if (showBiometrics)
          TextButton.icon(
            onPressed: onBiometrics,
            icon: const Icon(Icons.fingerprint, color: Colors.white70),
            label: Text(
              biometricsLabel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      postDueScheduledItems(ref.read(databaseProvider));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only lock when fully backgrounded. `inactive`/`hidden` fire during Face ID.
    if (state == AppLifecycleState.paused) {
      ref.read(lockControllerProvider.notifier).onAppPaused();
    }
    if (state == AppLifecycleState.resumed) {
      postDueScheduledItems(ref.read(databaseProvider));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(lockControllerProvider);
    if (lock.needsLock) return const LockScreen();
    return widget.child;
  }
}
