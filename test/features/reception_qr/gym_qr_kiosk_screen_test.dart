import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ugym_business/features/reception_qr/domain/kiosk_security.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/features/reception_qr/presentation/gym_qr_kiosk_screen.dart';
import 'package:ugym_core/ugym_core.dart';

final class _SpyWakeLock implements KioskWakeLock {
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async {
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
  }
}

final class _FakeQrRepository implements ReceptionVisitsRepository {
  _FakeQrRepository(this.nowProvider);

  final DateTime Function() nowProvider;
  int fetchCalls = 0;

  @override
  Future<GymQrToken> fetchGymQr({required int gymId}) async {
    fetchCalls++;
    final now = nowProvider();
    return GymQrToken(
      gymId: gymId,
      gymName: 'Atlas Central',
      slot: 100 + fetchCalls,
      token: 'gym|$gymId|${100 + fetchCalls}|hmac',
      ttlSeconds: 60,
      expiresAt: now.add(const Duration(seconds: 60)),
    );
  }

  @override
  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<List<VisitRecord>> listCompanyVisits() => throw UnimplementedError();

  @override
  Future<List<VisitRecord>> listClientVisits({required int clientId}) =>
      throw UnimplementedError();

  @override
  Future<CheckInResult> registerManualVisit({
    required int clientId,
    required int gymId,
    DateTime? visitedAt,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<VisitRecord> cancelVisit({
    required int visitId,
    required String reason,
  }) => throw UnimplementedError();
}

void main() {
  group('KioskPinGuard', () {
    test('stores salted SHA-256 hash and verifies 4-digit PIN', () async {
      final storage = InMemoryTokenStorage();
      final guard = KioskPinGuard(storage: storage);

      expect(await guard.isLocked(), isFalse);
      await guard.lockWithPin('4821');
      expect(await guard.isLocked(), isTrue);

      final storedHash = await storage.read('ugym_business_kiosk_pin_hash');
      expect(storedHash, isNotNull);
      expect(storedHash, isNot('4821'));
      expect(storedHash!.length, 64); // SHA-256 hex digest length

      expect(await guard.unlockWithPin('0000'), isFalse);
      expect(await guard.isLocked(), isTrue);

      expect(await guard.unlockWithPin('4821'), isTrue);
      expect(await guard.isLocked(), isFalse);
    });
  });

  group('GymQrKioskScreen', () {
    testWidgets(
      'enables WakeLock, auto-refreshes before expiry, and stops on dispose',
      (tester) async {
        var fakeNow = DateTime.utc(2026, 11, 17, 7, 0, 0);
        final wakeLock = _SpyWakeLock();
        final repo = _FakeQrRepository(() => fakeNow);
        final pinGuard = KioskPinGuard(storage: InMemoryTokenStorage());

        await tester.pumpWidget(
          MaterialApp(
            theme: UcraftTheme.light(),
            home: GymQrKioskScreen(
              gymId: 1,
              repository: repo,
              pinGuard: pinGuard,
              wakeLock: wakeLock,
              clock: () => fakeNow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(wakeLock.enableCalls, 1);
        expect(repo.fetchCalls, 1);
        expect(find.text('Atlas Central'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('Обновление через 60 сек'), findsOneWidget);

        // Advance time to 4 seconds before expiry -> triggers refresh.
        fakeNow = fakeNow.add(const Duration(seconds: 56));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(repo.fetchCalls, 2);
        expect(find.text('Слот #102'), findsOneWidget);

        // Unmount kiosk screen -> disables WakeLock and cancels timer.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(wakeLock.disableCalls, 1);

        fakeNow = fakeNow.add(const Duration(seconds: 58));
        await tester.pump(const Duration(seconds: 1));
        expect(repo.fetchCalls, 2);
      },
    );

    testWidgets('locks exit with PIN and only exits after valid PIN', (
      tester,
    ) async {
      final fakeNow = DateTime.utc(2026, 11, 17, 7, 0, 0);
      final repo = _FakeQrRepository(() => fakeNow);
      final pinGuard = KioskPinGuard(storage: InMemoryTokenStorage());
      var exited = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.dark(),
          home: GymQrKioskScreen(
            gymId: 1,
            repository: repo,
            pinGuard: pinGuard,
            clock: () => fakeNow,
            onExitKiosk: () => exited = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Заблокировать киоск PIN-кодом'));
      await tester.tap(find.text('Заблокировать киоск PIN-кодом'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('kiosk_set_pin_input')),
        '2580',
      );
      await tester.ensureVisible(find.text('Включить блокировку киоска'));
      await tester.tap(find.text('Включить блокировку киоска'));
      await tester.pumpAndSettle();

      expect(find.text('Киоск заблокирован'), findsOneWidget);
      expect(find.text('Выйти из режима киоска'), findsNothing);

      await tester.ensureVisible(find.text('Разблокировать и выйти'));
      await tester.tap(find.text('Разблокировать и выйти'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('kiosk_unlock_pin_input')),
        '9999',
      );
      await tester.ensureVisible(find.text('Подтвердить PIN'));
      await tester.tap(find.text('Подтвердить PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Неверный PIN-код'), findsOneWidget);
      expect(exited, isFalse);

      await tester.enterText(
        find.byKey(const ValueKey<String>('kiosk_unlock_pin_input')),
        '2580',
      );
      await tester.ensureVisible(find.text('Подтвердить PIN'));
      await tester.tap(find.text('Подтвердить PIN'));
      await tester.pumpAndSettle();

      expect(exited, isTrue);
    });
  });
}
