import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
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
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled') return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authMessage(tr, e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authMessage(Tr tr, FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return tr.authInvalidEmail;
      case 'weak-password':
        return tr.authWeakPassword;
      case 'wrong-password':
      case 'invalid-credential':
        return tr.authWrongPassword;
      case 'user-disabled':
        return tr.authUserDisabled;
      case 'too-many-requests':
        return tr.authTooMany;
      case 'canceled':
      case 'ERROR_ABORTED_BY_USER':
        return tr.authCanceled;
      default:
        return e.message ?? tr.authFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final auth = ref.read(cloudAuthProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(first: tr.signIn, onBack: () => context.pop()),
            const SizedBox(height: 24),
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
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(hintText: tr.password),
            ),
            const SizedBox(height: 12),
            FilledButton(
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
            OutlinedButton(
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
            TextButton(
              onPressed: _busy ? null : () => context.pop(),
              child: Text(tr.continueWithoutAccount),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
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
    return GestureDetector(
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
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.primaryText)),
            ],
          ),
        ),
      ),
    );
  }
}
