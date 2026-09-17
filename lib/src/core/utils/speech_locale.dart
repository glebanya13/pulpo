// Shared speech-to-text helpers for assistant + voice entry screens.

String speechLocaleId(String locale) => switch (locale) {
      'uk' => 'uk_UA',
      'ru' => 'ru_RU',
      'en' => 'en_US',
      _ => 'es_ES',
    };

/// Soft STT errors that should resume listening instead of hard-stopping.
bool isSoftSpeechError(Object error) {
  final msg = error.toString().toLowerCase();
  return msg.contains('no_match') ||
      msg.contains('no_speech') ||
      msg.contains('speech_timeout') ||
      msg.contains('busy') ||
      msg.contains('client');
}

/// Format listen duration as `m:ss`.
String formatListenMmSs(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
