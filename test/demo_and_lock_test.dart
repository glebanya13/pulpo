import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/data/repositories/backup_service.dart';
import 'package:pulpo/src/features/security/lock_controller.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  group('BackupService.payloadLooksLikeDemo', () {
    Map<String, dynamic> demoPayload({
      int txs = 8,
      List<double> balances = const [420, 1860],
    }) {
      return {
        'accounts': [
          for (var i = 0; i < balances.length; i++)
            {'id': i + 1, 'initialBalance': balances[i]},
        ],
        'transactions': List.generate(txs, (i) => {'id': i}),
      };
    }

    test('matches App Review sample shape', () {
      expect(BackupService.payloadLooksLikeDemo(demoPayload()), isTrue);
    });

    test('rejects wrong balances', () {
      expect(
        BackupService.payloadLooksLikeDemo(
          demoPayload(balances: const [100, 200]),
        ),
        isFalse,
      );
    });

    test('rejects wrong account count', () {
      expect(
        BackupService.payloadLooksLikeDemo({
          'accounts': [
            {'initialBalance': 420},
          ],
          'transactions': List.generate(8, (i) => {'id': i}),
        }),
        isFalse,
      );
    });

    test('rejects too few / too many txs', () {
      expect(
        BackupService.payloadLooksLikeDemo(demoPayload(txs: 3)),
        isFalse,
      );
      expect(
        BackupService.payloadLooksLikeDemo(demoPayload(txs: 20)),
        isFalse,
      );
    });
  });

  group('lock helpers', () {
    test('hashLockPin is stable and salted', () {
      expect(hashLockPin('1234'), hashLockPin('1234'));
      expect(hashLockPin('1234'), isNot(hashLockPin('1235')));
      expect(hashLockPin('1234'), isNot('1234'));
    });

    test('biometricsLikelyAvailable prefers canCheck over empty enrolled', () {
      expect(
        biometricsLikelyAvailable(
          canCheck: true,
          deviceSupported: true,
          enrolled: const [],
        ),
        isTrue,
      );
      expect(
        biometricsLikelyAvailable(
          canCheck: false,
          deviceSupported: true,
          enrolled: const [],
        ),
        isFalse,
      );
      expect(
        biometricsLikelyAvailable(
          canCheck: false,
          deviceSupported: false,
          enrolled: const [BiometricType.face],
        ),
        isTrue,
      );
    });

    test('shouldAutoLockOnPause respects auth-in-progress grace', () {
      expect(
        shouldAutoLockOnPause(
          autoLock: true,
          hasLock: true,
          authInProgress: true,
        ),
        isFalse,
      );
      expect(
        shouldAutoLockOnPause(
          autoLock: true,
          hasLock: true,
          authInProgress: false,
        ),
        isTrue,
      );
      final now = DateTime(2026, 1, 1, 12);
      expect(
        shouldAutoLockOnPause(
          autoLock: true,
          hasLock: true,
          authInProgress: false,
          ignorePauseUntil: now.add(const Duration(seconds: 2)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
