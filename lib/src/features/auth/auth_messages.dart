import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/l10n/tr.dart';

String authErrorMessage(Tr tr, Object error) {
  if (error is SignInWithAppleAuthorizationException) {
    if (error.code == AuthorizationErrorCode.canceled) return tr.authCanceled;
    return error.message;
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
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
      case 'email-already-in-use':
        return tr.authEmailInUse;
      case 'network-request-failed':
        return tr.authNetworkError;
      default:
        return error.message ?? tr.authFailed;
    }
  }
  return tr.authFailed;
}

bool isAuthCanceled(Object error) {
  if (error is SignInWithAppleAuthorizationException) {
    return error.code == AuthorizationErrorCode.canceled;
  }
  if (error is FirebaseAuthException) {
    return error.code == 'canceled' || error.code == 'ERROR_ABORTED_BY_USER';
  }
  return false;
}
