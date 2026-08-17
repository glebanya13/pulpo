import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../widgets/common.dart';
import 'lock_controller.dart';
import 'pin_pad.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final lock = ref.watch(lockControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(first: tr.security, onBack: () => Navigator.pop(context)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _LockRow(
                    icon: LucideIcons.fingerprint,
                    color: const Color(0xFF7C6CFF),
                    title: tr.useBiometrics,
                    subtitle: tr.biometricLockHint,
                    value: lock.biometricsEnabled,
                    onChanged: (v) => _toggleBiometrics(v, tr),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 66, right: 16),
                    child: Divider(height: 1, color: context.divider),
                  ),
                  _LockRow(
                    icon: LucideIcons.lock,
                    color: const Color(0xFF8BD44A),
                    title: tr.pinCode,
                    subtitle: tr.pinCodeHint,
                    value: lock.pinEnabled,
                    onChanged: (v) => _togglePin(v, tr),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 66, right: 16),
                    child: Divider(height: 1, color: context.divider),
                  ),
                  _LockRow(
                    icon: LucideIcons.timer,
                    color: const Color(0xFF2EB5FF),
                    title: tr.autoLock,
                    subtitle: tr.autoLockHint,
                    value: lock.autoLock && lock.hasLock,
                    onChanged: lock.hasLock
                        ? (v) => ref
                            .read(lockControllerProvider.notifier)
                            .setAutoLock(v)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePin(bool on, Tr tr) async {
    if (on) {
      await _askPin();
      return;
    }
    await ref.read(lockControllerProvider.notifier).clearPin();
  }

  Future<void> _toggleBiometrics(bool on, Tr tr) async {
    final ctrl = ref.read(lockControllerProvider.notifier);
    if (!on) {
      await ctrl.setBiometrics(false);
      return;
    }
    final available = await ctrl.deviceHasBiometrics();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.biometricsUnavailable)),
      );
      return;
    }
    final ok = await ctrl.enableBiometrics();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.biometricsFailed)),
      );
    }
  }

  Future<bool?> _askPin() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _PinSetup(
        onSave: (pin) async {
          await ref.read(lockControllerProvider.notifier).setPin(pin);
        },
      ),
    );
    return ref.read(lockControllerProvider).pinEnabled;
  }
}

class _LockRow extends StatelessWidget {
  const _LockRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ColorWellIcon(
            color: color,
            icon: icon,
            size: 36,
            iconSize: 18,
            radius: 12,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: context.mutedText),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _PinSetup extends StatefulWidget {
  const _PinSetup({required this.onSave});
  final Future<void> Function(String pin) onSave;

  @override
  State<_PinSetup> createState() => _PinSetupState();
}

class _PinSetupState extends State<_PinSetup> {
  String _first = '';
  String _confirm = '';
  bool _repeat = false;
  String? _error;

  static const _len = 4;

  Future<void> _onChanged(String next) async {
    setState(() => _error = null);
    if (!_repeat) {
      setState(() => _first = next);
      if (next.length == _len) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        setState(() {
          _repeat = true;
          _confirm = '';
        });
      }
      return;
    }
    setState(() => _confirm = next);
    if (next.length != _len) return;
    if (next != _first) {
      setState(() {
        _error = Tr.of(context).pinMismatch;
        _confirm = '';
      });
      return;
    }
    await widget.onSave(next);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.handleBar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _repeat ? tr.confirmPin : tr.setPin,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.primaryText,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFE53E3E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          PinPad(
            length: _len,
            value: _repeat ? _confirm : _first,
            onChanged: _onChanged,
          ),
        ],
      ),
    );
  }
}

