import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/features/reception_qr/presentation/reception_scan_controller.dart';
import 'package:ugym_business/features/reception_qr/presentation/scan_client_qr_screen.dart';
import 'package:ugym_core/ugym_core.dart';

final class _ScriptedRepository implements ReceptionVisitsRepository {
  final List<Object> script = <Object>[];
  final List<String?> seenKeys = <String?>[];
  final List<String> seenTokens = <String>[];

  @override
  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  }) async {
    seenKeys.add(idempotencyKey);
    seenTokens.add(token);
    final next = script.removeAt(0);
    if (next is UgymApiException) {
      throw next;
    }
    return next as CheckInResult;
  }

  @override
  Future<GymQrToken> fetchGymQr({required int gymId}) =>
      throw UnimplementedError();

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

CheckInResult _result({int? remaining = 7}) => CheckInResult(
  id: 1,
  companyId: 1,
  gymId: 1,
  clientId: 9,
  membershipId: 33,
  method: VisitMethod.clientQr,
  status: VisitStatus.completed,
  visitedAt: DateTime.utc(2026, 11, 17, 7),
  visitDate: '2026-11-17',
  remainingVisits: remaining,
);

Widget _fakeScanner(BuildContext context, ValueChanged<String> onDetect) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => onDetect('client-qr-1'),
          child: const Text('simulate-scan'),
        ),
        ElevatedButton(
          onPressed: () => onDetect('client-qr-2'),
          child: const Text('simulate-scan-2'),
        ),
      ],
    ),
  );
}

void main() {
  group('ReceptionScanController', () {
    test(
      'ignores codes while processing and reuses key on network retry',
      () async {
        final repo = _ScriptedRepository()
          ..script.addAll(<Object>[
            const UgymApiException(
              code: 'NETWORK_ERROR',
              message: 'offline',
              isNetworkError: true,
            ),
            _result(),
          ]);
        final controller = ReceptionScanController(repository: repo, gymId: 1);

        await controller.onCodeScanned('client-qr-1');
        expect(controller.phase, ScanPhase.networkError);
        final firstKey = controller.pendingIdempotencyKey;
        expect(firstKey, isNotNull);

        // Scanner is paused: a second code must be ignored.
        await controller.onCodeScanned('client-qr-2');
        expect(repo.seenTokens, <String>['client-qr-1']);

        await controller.retry();
        expect(controller.phase, ScanPhase.success);
        expect(repo.seenKeys, <String?>[firstKey, firstKey]);
        expect(repo.seenTokens, <String>['client-qr-1', 'client-qr-1']);
      },
    );

    test('uses a fresh key for the next client after scanNext', () async {
      final repo = _ScriptedRepository()
        ..script.addAll(<Object>[_result(), _result()]);
      final controller = ReceptionScanController(repository: repo, gymId: 1);

      await controller.onCodeScanned('a');
      controller.scanNext();
      await controller.onCodeScanned('b');

      expect(repo.seenKeys[0], isNot(repo.seenKeys[1]));
    });
  });

  group('ScanClientQrScreen', () {
    Widget wrap(Widget child, {ThemeData? theme}) {
      return MaterialApp(theme: theme ?? UcraftTheme.light(), home: child);
    }

    testWidgets('shows success card with remaining visits', (tester) async {
      final repo = _ScriptedRepository()..script.add(_result(remaining: 7));
      final controller = ReceptionScanController(repository: repo, gymId: 1);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          ScanClientQrScreen(
            controller: controller,
            scannerBuilder: _fakeScanner,
          ),
        ),
      );

      await tester.tap(find.text('simulate-scan'));
      await tester.pumpAndSettle();

      expect(find.text('Посещение отмечено'), findsOneWidget);
      expect(find.text('Осталось занятий: 7'), findsOneWidget);

      await tester.tap(find.text('Сканировать следующего'));
      await tester.pumpAndSettle();
      expect(find.text('simulate-scan'), findsOneWidget);
    });

    testWidgets('shows large refusal screen for every 422 code in dark theme', (
      tester,
    ) async {
      const titles = <String, String>{
        'NO_ACTIVE_MEMBERSHIP': 'Нет активного абонемента',
        'MEMBERSHIP_FROZEN': 'Абонемент заморожен',
        'DAILY_LIMIT_EXCEEDED': 'Лимит входов на сегодня исчерпан',
        'OUTSIDE_ALLOWED_TIME': 'Вне разрешённого времени абонемента',
        'INVALID_QR_TOKEN': 'QR-код недействителен или устарел',
      };

      for (final entry in titles.entries) {
        final repo = _ScriptedRepository()
          ..script.add(
            UgymApiException(
              statusCode: 422,
              code: entry.key,
              message: 'Отказ: ${entry.key}',
            ),
          );
        final controller = ReceptionScanController(repository: repo, gymId: 1);
        var paymentsOpened = false;

        await tester.pumpWidget(
          wrap(
            ScanClientQrScreen(
              controller: controller,
              scannerBuilder: _fakeScanner,
              onOpenPayments: () => paymentsOpened = true,
            ),
            theme: UcraftTheme.dark(),
          ),
        );

        await tester.tap(find.text('simulate-scan'));
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        expect(find.text('Отказ: ${entry.key}'), findsOneWidget);

        if (entry.key == 'NO_ACTIVE_MEMBERSHIP') {
          await tester.tap(find.text('Принять оплату'));
          expect(paymentsOpened, isTrue);
        } else {
          expect(find.text('Принять оплату'), findsNothing);
        }
        controller.dispose();
      }
    });

    testWidgets('network error offers retry with same key', (tester) async {
      final repo = _ScriptedRepository()
        ..script.addAll(<Object>[
          const UgymApiException(
            code: 'NETWORK_ERROR',
            message: 'offline',
            isNetworkError: true,
          ),
          _result(),
        ]);
      final controller = ReceptionScanController(repository: repo, gymId: 1);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          ScanClientQrScreen(
            controller: controller,
            scannerBuilder: _fakeScanner,
          ),
        ),
      );

      await tester.tap(find.text('simulate-scan'));
      await tester.pumpAndSettle();
      expect(find.text('Нет связи с сервером'), findsOneWidget);

      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Посещение отмечено'), findsOneWidget);
      expect(repo.seenKeys.first, repo.seenKeys.last);
    });
  });
}
