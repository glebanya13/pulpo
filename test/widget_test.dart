import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/widgets/common.dart';

void main() {
  testWidgets('ErrorView shows message and retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: ErrorView(
            message: 'Load failed',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(find.text('Load failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(retried, isTrue);
  });
}
