import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/ai/ai_errors.dart';
import 'package:pulpo/src/core/ai/assistant_energy.dart';
import 'package:pulpo/src/core/ai/ai_local_parse.dart';
import 'package:pulpo/src/core/l10n/tr.dart';
import 'package:pulpo/src/core/utils/speech_locale.dart';
import 'package:pulpo/src/data/repositories/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('App Check / permission errors', () {
    test('classifyAiRawError maps App Check and DeviceCheck failures', () {
      expect(
        classifyAiRawError(
          'App Check getToken failed — firebaseappcheck',
        ),
        AiErrorCode.permissionDenied,
      );
      expect(
        classifyAiRawError(
          '[firebase_app_check/code-unsupported] DeviceCheckProvider',
        ),
        AiErrorCode.permissionDenied,
      );
      expect(
        classifyAiRawError('PERMISSION_DENIED: App attestation failed'),
        AiErrorCode.permissionDenied,
      );
      expect(
        classifyAiRawError('HTTP status code: 403'),
        AiErrorCode.permissionDenied,
      );
    });

    test('describeAiError surfaces permissionDenied for App Check', () {
      final tr = Tr.fromLang('ru');
      expect(
        describeAiError(
          tr,
          const PulpoAiException(
            AiErrorCode.permissionDenied,
            'App Check attestation failed',
          ),
        ),
        tr.aiPermissionDenied,
      );
    });
  });

  group('assistant energy', () {
    test('consumeMs drains and clamps free quota', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final energy = container.read(assistantEnergyProvider.notifier);
      expect(energy.state.hasEnergy, isTrue);

      final left = await energy.consumeMs(30 * 1000);
      expect(left, AssistantEnergy.freeQuota.inMilliseconds - 30 * 1000);
      expect(energy.state.units, lessThan(AssistantEnergy.maxUnits));

      await energy.consumeMs(AssistantEnergy.freeQuota.inMilliseconds);
      expect(energy.state.hasEnergy, isFalse);
      expect(energy.state.units, 0);
    });
  });

  group('speech locale helpers', () {
    test('speechLocaleId maps app locales', () {
      expect(speechLocaleId('ru'), 'ru_RU');
      expect(speechLocaleId('uk'), 'uk_UA');
      expect(speechLocaleId('en'), 'en_US');
      expect(speechLocaleId('es'), 'es_ES');
    });

    test('isSoftSpeechError ignores no_match / timeout', () {
      expect(isSoftSpeechError('error_no_match'), isTrue);
      expect(isSoftSpeechError('speech_timeout'), isTrue);
      expect(isSoftSpeechError('fatal microphone denied'), isFalse);
    });

    test('formatListenMmSs', () {
      expect(formatListenMmSs(0), '0:00');
      expect(formatListenMmSs(65), '1:05');
    });
  });

  group('local account parse', () {
    test('picks debit account from spoken phrase', () {
      final drafts = tryParseLocalTransactions(
        'такси 15 с карты тинькофф',
        currencyHint: 'EUR',
        categoryNames: const ['Транспорт'],
        accountNames: const ['Наличные', 'Карта Тинькофф'],
      );
      expect(drafts, isNotNull);
      expect(drafts!.first.accountHint, 'Карта Тинькофф');
    });
  });

  group('currency dropdown layout regression', () {
    testWidgets('currency menu row works with unbounded width', (tester) async {
      // DropdownMenuItem measures children with unbounded width; Expanded
      // there blanked "Nueva cuenta". Shrink-wrapping Row must stay valid.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnconstrainedBox(
              constrainedAxis: Axis.vertical,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('EUR'),
                  SizedBox(width: 6),
                  SizedBox(width: 18, height: 12),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('EUR'), findsOneWidget);
    });
  });
}
