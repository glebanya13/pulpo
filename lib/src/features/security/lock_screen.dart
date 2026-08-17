import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/scheduled_posting.dart';
import 'lock_controller.dart';
import 'pin_pad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lock = ref.read(lockControllerProvider);
      if (lock.biometricsEnabled) {
        ref.read(lockControllerProvider.notifier).tryBiometrics();
      }
    });
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
      if (next.length >= 8) {
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

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final lock = ref.watch(lockControllerProvider);
    final showPin = lock.pinEnabled;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 36),
              Image.asset('assets/logo.png', height: 64),
              const SizedBox(height: 24),
              Text(
                showPin ? tr.enterPin : tr.useBiometrics,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (showPin) ...[
                const Spacer(),
                PinPad(
                  length: lock.pinLengthKnown ? lock.pinLength : 8,
                  value: _pin,
                  onChanged: _onPin,
                  dark: true,
                ),
                const Spacer(),
              ] else
                const Spacer(),
              if (lock.biometricsEnabled)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(lockControllerProvider.notifier).tryBiometrics(),
                  icon: const Icon(Icons.fingerprint, color: Colors.white70),
                  label: Text(
                    tr.useBiometrics,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
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
