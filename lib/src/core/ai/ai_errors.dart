import '../l10n/tr.dart';
import 'pulpo_ai_service.dart';

String describeAiError(Tr tr, Object error) {
  if (error is! PulpoAiException) return tr.aiFailed;
  final code = error.message.split(':').first;
  switch (code) {
    case 'sign_in_required':
      return tr.proSignInRequired;
    case 'api_key':
    case 'api_not_enabled':
      return tr.aiApiNotEnabled;
    case 'permission_denied':
      return tr.aiPermissionDenied;
    case 'quota':
      return tr.aiQuotaExceeded;
    default:
      return tr.aiFailed;
  }
}
