import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/memberships/domain/memberships_models.dart';
import 'package:ugym_business/features/reception_qr/domain/kiosk_security.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/features/reception_qr/presentation/gym_qr_kiosk_screen.dart';
import 'package:ugym_business/features/reception_qr/presentation/reception_scan_controller.dart';
import 'package:ugym_business/features/reception_qr/presentation/scan_client_qr_screen.dart';
import 'package:ugym_business/features/sales/domain/sales_and_requests_models.dart';
import 'package:ugym_business/features/sales/presentation/membership_requests_and_sales_tabs.dart';
import 'package:ugym_business/features/sales/presentation/pos_and_products_screens.dart';
import 'package:ugym_core/ugym_core.dart';

final class _RateLimitAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        'error': <String, Object?>{
          'code': 'TOO_MANY_REQUESTS',
          'message': 'Слишком много запросов.',
        },
      }),
      429,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        'retry-after': <String>['45'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _ResilientSalesRepo implements SalesAndRequestsRepository {
  bool failNextSale = false;
  bool failNextPay = false;
  final List<({PaymentMethod method, String? key})> saleCalls =
      <({PaymentMethod method, String? key})>[];
  final List<({int requestId, PaymentMethod method, String? key})> payCalls =
      <({int requestId, PaymentMethod method, String? key})>[];

  @override
  Future<List<ProductItem>> listProducts({bool? onlyActive}) async => const [
    ProductItem(
      id: 4,
      name: 'Вода 0.5л',
      priceMinor: 500,
      currency: 'TJS',
      stockQuantity: 20,
      isActive: true,
    ),
  ];

  @override
  Future<SaleRecord> registerSale({
    int? clientId,
    required PaymentMethod paymentMethod,
    List<SaleProductLineInput> products = const <SaleProductLineInput>[],
    List<int> membershipTypeIds = const <int>[],
    String? idempotencyKey,
  }) async {
    saleCalls.add((method: paymentMethod, key: idempotencyKey));
    if (failNextSale) {
      failNextSale = false;
      throw const UgymApiException(
        code: 'NETWORK_ERROR',
        message: 'Потеряна связь',
        isNetworkError: true,
      );
    }
    return SaleRecord(
      id: 70,
      companyId: 1,
      clientId: clientId,
      status: SaleStatus.paid,
      paymentMethod: paymentMethod,
      totalMinor: 500,
      currency: 'TJS',
      acceptedByUserId: 2,
      paidAt: DateTime.utc(2026, 11, 18, 10, 0),
      items: const [],
    );
  }

  @override
  Future<List<MembershipRequestRecord>> listMembershipRequests({
    MembershipRequestStatus? status,
  }) async => [
    MembershipRequestRecord(
      id: 81,
      companyId: 1,
      gymId: 10,
      userId: 5,
      clientId: 11,
      membershipTypeId: 3,
      status: MembershipRequestStatus.pending,
      expiresAt: DateTime.utc(2026, 11, 19, 12, 0),
    ),
  ];

  @override
  Future<PayRequestResult> payMembershipRequest({
    required int requestId,
    required PaymentMethod paymentMethod,
    String? idempotencyKey,
  }) async {
    payCalls.add((
      requestId: requestId,
      method: paymentMethod,
      key: idempotencyKey,
    ));
    if (failNextPay) {
      failNextPay = false;
      throw const UgymApiException(
        code: 'NETWORK_ERROR',
        message: 'Таймаут сети',
        isNetworkError: true,
      );
    }
    return PayRequestResult(
      requestId: requestId,
      saleId: 71,
      membershipId: 52,
      clientId: 11,
      status: MembershipRequestStatus.paid,
      paidAt: DateTime.utc(2026, 11, 18, 12, 0),
    );
  }

  @override
  Future<MembershipRequestStatus> cancelMembershipRequest({
    required int requestId,
    String? reason,
  }) => throw UnimplementedError();

  @override
  Future<int> createProduct({
    required String name,
    required int priceMinor,
    String? currency,
    int? stockQuantity,
  }) => throw UnimplementedError();

  @override
  Future<List<SaleRecord>> listClientSales({required int clientId}) =>
      throw UnimplementedError();

  @override
  Future<List<SaleRecord>> listSales() => throw UnimplementedError();

  @override
  Future<SaleRecord> refundSale({
    required int saleId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<ProductItem> updateProduct({
    required int productId,
    bool? isActive,
    int? stockQuantity,
  }) => throw UnimplementedError();
}

final class _FakeMembershipsRepo implements MembershipsRepository {
  @override
  Future<List<MembershipType>> listMembershipTypes({bool? onlyActive}) async =>
      const [];

  @override
  Future<ClientMembership> cancelMembership({
    required int membershipId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<int> createMembershipType(CreateMembershipTypeInput input) =>
      throw UnimplementedError();

  @override
  Future<MembershipFreezeState> freezeMembership({required int membershipId}) =>
      throw UnimplementedError();

  @override
  Future<List<ClientMembership>> listClientMemberships({
    required int clientId,
  }) => throw UnimplementedError();

  @override
  Future<List<ClientMembership>> listExpiringMemberships() =>
      throw UnimplementedError();

  @override
  Future<bool> setMembershipTypeActive({
    required int typeId,
    required bool isActive,
  }) => throw UnimplementedError();

  @override
  Future<MembershipFreezeState> unfreezeMembership({
    required int membershipId,
  }) => throw UnimplementedError();
}

final class _ResilientVisitsRepo implements ReceptionVisitsRepository {
  _ResilientVisitsRepo({required this.nowProvider});

  final DateTime Function() nowProvider;
  final List<Object> checkInScript = <Object>[];
  final List<String?> seenCheckInKeys = <String?>[];
  final List<Object> qrScript = <Object>[];

  @override
  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  }) async {
    seenCheckInKeys.add(idempotencyKey);
    final next = checkInScript.removeAt(0);
    if (next is CheckInResult) {
      return next;
    }
    throw next;
  }

  @override
  Future<GymQrToken> fetchGymQr({required int gymId}) async {
    final next = qrScript.removeAt(0);
    if (next is GymQrToken) {
      return next;
    }
    throw next;
  }

  @override
  Future<VisitRecord> cancelVisit({
    required int visitId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<List<VisitRecord>> listClientVisits({required int clientId}) =>
      throw UnimplementedError();

  @override
  Future<List<VisitRecord>> listCompanyVisits() => throw UnimplementedError();

  @override
  Future<CheckInResult> registerManualVisit({
    required int clientId,
    required int gymId,
    DateTime? visitedAt,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  test(
    'UgymErrorMapper extracts Retry-After seconds on 429 TOO_MANY_REQUESTS',
    () async {
      final client = UgymHttpClient(
        baseUrl: 'https://api.ugym.tj/api/v1',
        tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
      );
      client.dio.httpClientAdapter = _RateLimitAdapter();

      try {
        await client.dio.get<Object?>('/business/visits');
        fail('Expected DioException for 429');
      } on DioException catch (error) {
        final apiError = error.error! as UgymApiException;
        expect(apiError.statusCode, 429);
        expect(apiError.code, 'TOO_MANY_REQUESTS');
        expect(apiError.isRateLimited, isTrue);
        expect(apiError.retryAfterSeconds, 45);
        expect(apiError.message, contains('Повторите через 45 сек.'));
      }
    },
  );

  testWidgets(
    'PosCheckoutScreen keeps Idempotency-Key on retry and invalidates on payload change',
    (tester) async {
      final repo = _ResilientSalesRepo()..failNextSale = true;
      var seq = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: PosCheckoutScreen(
            salesRepository: repo,
            membershipsRepository: _FakeMembershipsRepo(),
            idempotencyKeyGenerator: () => 'sale-key-${++seq}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Провести продажу'));
      await tester.tap(find.text('Провести продажу'));
      await tester.pumpAndSettle();

      expect(find.text('Потеряна связь'), findsOneWidget);
      expect(repo.saleCalls.single.key, 'sale-key-1');

      // Retrying same payload sends identical key.
      repo.failNextSale = true;
      await tester.tap(find.text('Провести продажу'));
      await tester.pumpAndSettle();
      expect(repo.saleCalls[1].key, 'sale-key-1');

      // Changing payment method invalidates key and generates a new one.
      await tester.ensureVisible(find.text('Перевод'));
      await tester.tap(find.text('Перевод'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Провести продажу'));
      await tester.tap(find.text('Провести продажу'));
      await tester.pumpAndSettle();

      expect(repo.saleCalls, hasLength(3));
      expect(repo.saleCalls[2].method, PaymentMethod.transfer);
      expect(repo.saleCalls[2].key, 'sale-key-2');
    },
  );

  testWidgets(
    'MembershipRequestsQueueTab preserves Idempotency-Key across dialog close and reopen',
    (tester) async {
      final repo = _ResilientSalesRepo()..failNextPay = true;
      var seq = 0;
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.admin,
      );
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MembershipRequestsQueueTab(
                repository: repo,
                sessionController: session,
                clock: () => DateTime.utc(2026, 11, 18, 12, 0),
                idempotencyKeyGenerator: () => 'req-key-${++seq}',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First attempt fails with network timeout.
      await tester.tap(find.text('Принять оплату'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подтвердить оплату'));
      await tester.pumpAndSettle();

      expect(find.text('Таймаут сети'), findsOneWidget);
      expect(repo.payCalls.single.key, 'req-key-1');

      // Close dialog, reopen it for same request and method -> must keep req-key-1.
      await tester.tap(find.text('Назад'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Принять оплату'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подтвердить оплату'));
      await tester.pumpAndSettle();

      expect(repo.payCalls, hasLength(2));
      expect(repo.payCalls[0].key, 'req-key-1');
      expect(repo.payCalls[1].key, 'req-key-1');
    },
  );

  testWidgets(
    'ScanClientQrScreen preserves Idempotency-Key across 429 Retry-After and unexpected errors',
    (tester) async {
      final fakeNow = DateTime.utc(2026, 11, 18, 12, 0);
      final repo = _ResilientVisitsRepo(nowProvider: () => fakeNow)
        ..checkInScript.addAll(<Object>[
          const UgymApiException(
            statusCode: 429,
            code: 'TOO_MANY_REQUESTS',
            message: 'Слишком много попыток (Повторите через 15 сек.)',
            retryAfterSeconds: 15,
          ),
          StateError('socket closed unexpectedly'),
          CheckInResult(
            id: 10,
            companyId: 1,
            gymId: 1,
            clientId: 9,
            membershipId: 33,
            method: VisitMethod.clientQr,
            status: VisitStatus.completed,
            visitedAt: DateTime.utc(2026, 11, 18, 12, 0),
            visitDate: '2026-11-18',
            remainingVisits: 5,
          ),
        ]);
      final controller = ReceptionScanController(repository: repo, gymId: 1);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: ScanClientQrScreen(
            controller: controller,
            scannerBuilder: (context, onDetect) => Center(
              child: ElevatedButton(
                onPressed: () => onDetect('qr-token-abc'),
                child: const Text('scan'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('scan'));
      await tester.pumpAndSettle();

      expect(controller.phase, ScanPhase.networkError);
      expect(
        find.text('Слишком много попыток (Повторите через 15 сек.)'),
        findsOneWidget,
      );
      expect(find.text('Повторить'), findsOneWidget);

      // Retry hits unexpected StateError -> still stays in networkError with same key.
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(controller.phase, ScanPhase.networkError);

      // Second retry succeeds with exact same Idempotency-Key.
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(controller.phase, ScanPhase.success);
      expect(find.text('Посещение отмечено'), findsOneWidget);
      expect(repo.seenCheckInKeys, hasLength(3));
      expect(repo.seenCheckInKeys[0], isNotNull);
      expect(repo.seenCheckInKeys[1], repo.seenCheckInKeys[0]);
      expect(repo.seenCheckInKeys[2], repo.seenCheckInKeys[0]);
    },
  );

  testWidgets(
    'GymQrKioskScreen retains QR during transient refresh failure and recovers on next tick',
    (tester) async {
      var fakeNow = DateTime.utc(2026, 11, 18, 8, 0, 0);
      final repo = _ResilientVisitsRepo(nowProvider: () => fakeNow)
        ..qrScript.addAll(<Object>[
          GymQrToken(
            gymId: 1,
            gymName: 'Atlas Central',
            slot: 101,
            token: 'gym|1|101|hmac',
            ttlSeconds: 60,
            expiresAt: fakeNow.add(const Duration(seconds: 60)),
          ),
          StateError('network dropped'),
          GymQrToken(
            gymId: 1,
            gymName: 'Atlas Central',
            slot: 102,
            token: 'gym|1|102|hmac',
            ttlSeconds: 60,
            expiresAt: fakeNow.add(const Duration(seconds: 120)),
          ),
        ]);
      final pinGuard = KioskPinGuard(storage: InMemoryTokenStorage());

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: GymQrKioskScreen(
            gymId: 1,
            repository: repo,
            pinGuard: pinGuard,
            clock: () => fakeNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Слот #101'), findsOneWidget);

      // Refresh at T+56s fails with unexpected error -> QR stays visible with warning.
      fakeNow = fakeNow.add(const Duration(seconds: 56));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Слот #101'), findsOneWidget);
      expect(find.text('Не удалось обновить QR-код зала.'), findsOneWidget);

      // Next tick recovers and clears error banner.
      fakeNow = fakeNow.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Слот #102'), findsOneWidget);
      expect(find.text('Не удалось обновить QR-код зала.'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
