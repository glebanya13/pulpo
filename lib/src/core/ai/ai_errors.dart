import '../l10n/tr.dart';

enum AiErrorCode {
  signInRequired,
  apiKey,
  apiNotEnabled,
  permissionDenied,
  quota,
  blocked,
  emptyResponse,
  emptyInput,
  invalidJson,
  missingModel,
  network,
  requestFailed,
}

class PulpoAiException implements Exception {
  const PulpoAiException(this.code, [this.detail]);

  final AiErrorCode code;
  final String? detail;

  /// Soft-fail assistant JSON turn into plain chat.
  bool get allowsChatFallback =>
      code == AiErrorCode.invalidJson ||
      code == AiErrorCode.emptyResponse ||
      code == AiErrorCode.requestFailed ||
      code == AiErrorCode.network ||
      code == AiErrorCode.missingModel;

  bool get isRetryable =>
      code == AiErrorCode.emptyResponse ||
      code == AiErrorCode.permissionDenied ||
      code == AiErrorCode.missingModel ||
      code == AiErrorCode.network;

  @override
  String toString() {
    final d = detail?.trim();
    if (d == null || d.isEmpty) return 'PulpoAiException(${code.name})';
    return 'PulpoAiException(${code.name}: $d)';
  }
}

/// Map raw Firebase / Gemini exception text to a typed code.
AiErrorCode classifyAiRawError(String msg) {
  final m = msg.toLowerCase();

  if (m.contains('blocked') ||
      m.contains('safety') ||
      m.contains('finishreason.safety')) {
    return AiErrorCode.blocked;
  }
  if (m.contains('api key') || m.contains('invalidapikey')) {
    return AiErrorCode.apiKey;
  }
  if (m.contains('not enabled') || m.contains('serviceapinotenabled')) {
    return AiErrorCode.apiNotEnabled;
  }
  if (m.contains('quota') ||
      m.contains('resource_exhausted') ||
      m.contains('prepayment') ||
      m.contains('depleted') ||
      m.contains('billing account') ||
      m.contains('no credits')) {
    return AiErrorCode.quota;
  }
  if (m.contains('not_found') ||
      m.contains('not found') ||
      m.contains('not supported') ||
      m.contains('model_not_found')) {
    return AiErrorCode.missingModel;
  }
  if (m.contains('permission') ||
      m.contains('app check') ||
      m.contains('app-check') ||
      m.contains('firebaseappcheck') ||
      m.contains('appcheck') ||
      m.contains('unauthenticated') ||
      RegExp(r'\b403\b').hasMatch(m)) {
    return AiErrorCode.permissionDenied;
  }
  if (m.contains('unavailable') ||
      m.contains('deadline') ||
      m.contains('timeout') ||
      m.contains('socket') ||
      m.contains('network') ||
      m.contains('connection') ||
      RegExp(r'\b5\d\d\b').hasMatch(m) ||
      m.contains('server error')) {
    return AiErrorCode.network;
  }
  return AiErrorCode.requestFailed;
}

String describeAiError(Tr tr, Object error) {
  if (error is! PulpoAiException) {
    final raw = error.toString().trim();
    if (raw.isEmpty) return tr.aiFailed;
    final short = raw.length > 160 ? '${raw.substring(0, 160)}…' : raw;
    return '${tr.aiFailed}\n$short';
  }
  switch (error.code) {
    case AiErrorCode.signInRequired:
      return tr.proSignInRequired;
    case AiErrorCode.apiKey:
    case AiErrorCode.apiNotEnabled:
      return tr.aiApiNotEnabled;
    case AiErrorCode.permissionDenied:
      return tr.aiPermissionDenied;
    case AiErrorCode.quota:
      final detail = (error.detail ?? '').toLowerCase();
      if (detail.contains('prepayment') ||
          detail.contains('depleted') ||
          detail.contains('billing') ||
          detail.contains('no credits')) {
        return tr.aiBillingDepleted;
      }
      return tr.aiQuotaExceeded;
    case AiErrorCode.blocked:
      return tr.aiBlocked;
    case AiErrorCode.emptyResponse:
      return tr.aiEmptyResponse;
    case AiErrorCode.invalidJson:
      return tr.aiInvalidResponse;
    case AiErrorCode.emptyInput:
    case AiErrorCode.missingModel:
    case AiErrorCode.network:
    case AiErrorCode.requestFailed:
      final detail = error.detail?.trim() ?? '';
      if (detail.isEmpty) return tr.aiFailed;
      // Always surface a short backend reason — otherwise "aiFailed" alone
      // is useless for TestFlight / customer reports.
      final short =
          detail.length > 160 ? '${detail.substring(0, 160)}…' : detail;
      return '${tr.aiFailed}\n$short';
  }
}
