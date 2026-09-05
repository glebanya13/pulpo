import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import 'auth_messages.dart';
import 'cloud_auth.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    final tr = Tr.of(context);
    setState(() => _busy = true);
    try {
      await fn();
      if (mounted) context.pop();
    } catch (e) {
      if (isAuthCanceled(e)) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(tr, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final auth = ref.read(cloudAuthProvider);
    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(first: tr.signIn, onBack: () => context.pop()),
        headerGap: 24,
        children: [
          _GuestInfoCard(text: tr.signInGuestInfo),
          const SizedBox(height: 20),
          _Btn(
            icon: Icons.apple,
            label: tr.signInApple,
            onTap: _busy ? null : () => _run(auth.signInWithApple),
          ),
          const SizedBox(height: 10),
          _Btn(
            icon: Icons.g_mobiledata,
            label: tr.signInGoogle,
            onTap: _busy ? null : () => _run(auth.signInWithGoogle),
          ),
          const SizedBox(height: 24),
          Text(tr.signInEmail,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(hintText: tr.email),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(hintText: tr.password),
          ),
          const SizedBox(height: 16),
          ScaledFilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => auth.signInWithEmail(
                        _email.text,
                        _password.text,
                      ),
                    ),
            child: Text(tr.signIn),
          ),
          const SizedBox(height: 8),
          ScaledOutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => auth.registerWithEmail(
                        _email.text,
                        _password.text,
                      ),
                    ),
            child: Text(tr.register),
          ),
          const SizedBox(height: 8),
          ScaledTextButton(
            onPressed: _busy ? null : () => context.pop(),
            child: Text(tr.continueWithoutAccount),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _GuestInfoCard extends StatelessWidget {
  const _GuestInfoCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 16, color: context.mutedText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.primaryText),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
