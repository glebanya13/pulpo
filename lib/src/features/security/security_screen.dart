import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';
import 'lock_controller.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

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
            _Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(tr.pinCode),
                    value: lock.pinEnabled,
                    activeThumbColor: AppColors.ink,
                    onChanged: (v) async {
                      if (v) {
                        _error = null;
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.viewInsetsOf(context).bottom,
                            ),
                            child: _PinSetup(
                              pin: _pin,
                              pin2: _pin2,
                              error: _error,
                              onSave: () async {
                                if (_pin.text.length < 4 ||
                                    _pin.text != _pin2.text) {
                                  setState(() => _error = tr.pinMismatch);
                                  return;
                                }
                                await ref
                                    .read(lockControllerProvider.notifier)
                                    .setPin(_pin.text);
                                _pin.clear();
                                _pin2.clear();
                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      } else {
                        await ref.read(lockControllerProvider.notifier).clearPin();
                      }
                    },
                  ),
                  SwitchListTile(
                    title: Text(tr.useBiometrics),
                    value: lock.biometricsEnabled,
                    activeThumbColor: AppColors.ink,
                    onChanged: lock.pinEnabled
                        ? (v) => ref
                            .read(lockControllerProvider.notifier)
                            .setBiometrics(v)
                        : null,
                  ),
                  SwitchListTile(
                    title: Text(tr.autoLock),
                    value: lock.autoLock,
                    activeThumbColor: AppColors.ink,
                    onChanged: lock.pinEnabled
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
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _PinSetup extends StatelessWidget {
  const _PinSetup({
    required this.pin,
    required this.pin2,
    required this.onSave,
    this.error,
  });
  final TextEditingController pin;
  final TextEditingController pin2;
  final VoidCallback onSave;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr.setPin,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(hintText: tr.setPin),
          ),
          TextField(
            controller: pin2,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(hintText: tr.confirmPin, errorText: error),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onSave, child: Text(tr.save)),
        ],
      ),
    );
  }
}
