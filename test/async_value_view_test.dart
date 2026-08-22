import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/app_startup.dart';
import 'package:pulpo/src/core/l10n/tr.dart';
import 'package:pulpo/src/widgets/async_value_view.dart';
import 'package:pulpo/src/widgets/startup_banner.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(body: child),
      ),
    );
  }

  test('dataLoadErrorMessage maps sqlite and network errors', () {
    final tr = Tr.fromLang('en');
    expect(
      dataLoadErrorMessage(tr, Exception('SqliteException: disk I/O')),
      tr.dataLoadDbError,
    );
    expect(
      dataLoadErrorMessage(tr, Exception('SocketException: failed host lookup')),
      tr.dataLoadNetworkError,
    );
    expect(
      dataLoadErrorMessage(tr, Exception('something else')),
      tr.dataLoadGenericError,
    );
  });

  testWidgets('AsyncValueView shows error with retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      wrap(
        AsyncValueView<int>(
          value: AsyncValue.error(Exception('SqliteException'), StackTrace.empty),
          onRetry: () => retried = true,
          data: (_) => const Text('data'),
        ),
      ),
    );
    expect(find.textContaining('database', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(retried, isTrue);
  });

  testWidgets('AsyncValuesGate blocks child while loading', (tester) async {
    await tester.pumpWidget(
      wrap(
        AsyncValuesGate(
          values: const [
            AsyncValue<int>.loading(),
            AsyncValue.data(1),
          ],
          child: const Text('loaded'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('loaded'), findsNothing);
  });

  testWidgets('StartupBannerHost shows firebase warning', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStartupProvider.overrideWith(
            (ref) => const AppStartupState(
              firebaseError: 'init failed',
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          home: StartupBannerHost(
            child: const Text('app body'),
          ),
        ),
      ),
    );
    expect(find.textContaining('Firebase', findRichText: true), findsOneWidget);
    expect(find.text('app body'), findsOneWidget);
  });
}
