import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/memberships/domain/memberships_models.dart';
import 'package:ugym_business/features/sales/domain/sales_and_requests_models.dart';
import 'package:ugym_business/features/sales/presentation/membership_requests_and_sales_tabs.dart';
import 'package:ugym_business/features/sales/presentation/pos_and_products_screens.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeSalesRepo implements SalesAndRequestsRepository {
  List<MembershipRequestRecord> requests = [
    MembershipRequestRecord(
      id: 81,
      companyId: 1,
      gymId: 10,
      userId: 5,
      clientId: 11,
      membershipTypeId: 3,
      status: MembershipRequestStatus.pending,
      expiresAt: DateTime.utc(2026, 11, 18, 12, 0),
    ),
  ];

  List<ProductItem> products = const [
    ProductItem(
      id: 4,
      name: 'Вода 0.5л',
      priceMinor: 500,
      currency: 'TJS',
      stockQuantity: 20,
      isActive: true,
    ),
  ];

  List<SaleRecord> sales = [
    SaleRecord(
      id: 70,
      companyId: 1,
      clientId: 11,
      status: SaleStatus.paid,
      paymentMethod: PaymentMethod.cash,
      totalMinor: 25000,
      currency: 'TJS',
      acceptedByUserId: 2,
      paidAt: DateTime.utc(2026, 11, 17, 10, 0),
      items: const [],
    ),
  ];

  bool failNextPay = false;
  bool failNextSale = false;
  final List<({int requestId, PaymentMethod method, String? key})> payCalls =
      <({int requestId, PaymentMethod method, String? key})>[];
  final List<({int? clientId, PaymentMethod method, String? key})> saleCalls =
      <({int? clientId, PaymentMethod method, String? key})>[];
  ({int saleId, String reason})? lastRefund;

  @override
  Future<List<MembershipRequestRecord>> listMembershipRequests({
    MembershipRequestStatus? status,
  }) async => requests;

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
      throw const UgymApiException(code: 'NETWORK_ERROR', message: 'Сбой сети');
    }
    return PayRequestResult(
      requestId: requestId,
      saleId: 71,
      membershipId: 52,
      clientId: 11,
      status: MembershipRequestStatus.paid,
      paidAt: DateTime.utc(2026, 11, 17, 12, 0),
    );
  }

  @override
  Future<MembershipRequestStatus> cancelMembershipRequest({
    required int requestId,
    String? reason,
  }) async => MembershipRequestStatus.cancelled;

  @override
  Future<List<ProductItem>> listProducts({bool? onlyActive}) async => products;

  @override
  Future<int> createProduct({
    required String name,
    required int priceMinor,
    String? currency,
    int? stockQuantity,
  }) async => 99;

  @override
  Future<ProductItem> updateProduct({
    required int productId,
    bool? isActive,
    int? stockQuantity,
  }) async => products.first;

  @override
  Future<List<SaleRecord>> listSales() async => sales;

  @override
  Future<SaleRecord> registerSale({
    int? clientId,
    required PaymentMethod paymentMethod,
    List<SaleProductLineInput> products = const <SaleProductLineInput>[],
    List<int> membershipTypeIds = const <int>[],
    String? idempotencyKey,
  }) async {
    saleCalls.add((
      clientId: clientId,
      method: paymentMethod,
      key: idempotencyKey,
    ));
    if (failNextSale) {
      failNextSale = false;
      throw const UgymApiException(
        code: 'NETWORK_ERROR',
        message: 'Потеряна связь',
      );
    }
    return sales.first;
  }

  @override
  Future<SaleRecord> refundSale({
    required int saleId,
    required String reason,
  }) async {
    lastRefund = (saleId: saleId, reason: reason);
    return SaleRecord(
      id: saleId,
      companyId: 1,
      clientId: 11,
      status: SaleStatus.refunded,
      paymentMethod: PaymentMethod.cash,
      totalMinor: 25000,
      currency: 'TJS',
      acceptedByUserId: 2,
      paidAt: DateTime.utc(2026, 11, 17, 10, 0),
      refundReason: reason,
      items: const [],
    );
  }

  @override
  Future<List<SaleRecord>> listClientSales({required int clientId}) {
    throw UnimplementedError();
  }
}

final class _FakeMembershipsRepo implements MembershipsRepository {
  @override
  Future<List<MembershipType>> listMembershipTypes({bool? onlyActive}) async =>
      const [
        MembershipType(
          id: 3,
          name: 'Безлимит 30д',
          kind: MembershipKind.unlimitedTime,
          startMode: MembershipStartMode.onPurchase,
          priceMinor: 25000,
          currency: 'TJS',
          dailyLimit: 1,
          isActive: true,
        ),
      ];

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

BusinessSessionController _session(BusinessRole role) {
  final prefs = AppPreferences(storage: InMemoryTokenStorage());
  return BusinessSessionController(preferences: prefs)..setRole(role);
}

void main() {
  testWidgets(
    'MembershipRequestsQueueTab pays request and preserves Idempotency-Key on retry',
    (tester) async {
      final repo = _FakeSalesRepo()..failNextPay = true;
      int seq = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MembershipRequestsQueueTab(
                repository: repo,
                sessionController: _session(BusinessRole.admin),
                clock: () => DateTime.utc(2026, 11, 17, 12, 0),
                idempotencyKeyGenerator: () => 'pay-key-${++seq}',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Заявка №81 • Тариф №3'), findsOneWidget);
      expect(find.text('осталось 24 ч 0 м'), findsOneWidget);

      await tester.tap(find.text('Принять оплату'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Терминал'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подтвердить оплату'));
      await tester.pumpAndSettle();

      expect(find.text('Сбой сети'), findsOneWidget);
      expect(repo.payCalls.single.key, 'pay-key-1');

      await tester.tap(find.text('Подтвердить оплату'));
      await tester.pumpAndSettle();

      expect(repo.payCalls.length, 2);
      expect(repo.payCalls[1].key, 'pay-key-1');
    },
  );

  testWidgets(
    'PosCheckoutScreen calculates total, requires client for membership, and preserves Idempotency-Key',
    (tester) async {
      final salesRepo = _FakeSalesRepo()..failNextSale = true;
      final membershipsRepo = _FakeMembershipsRepo();
      int seq = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: PosCheckoutScreen(
            salesRepository: salesRepo,
            membershipsRepository: membershipsRepo,
            idempotencyKeyGenerator: () => 'sale-key-${++seq}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Безлимит 30д (250\u00a0TJS)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();

      expect(find.text('Итого: 255,00\u00a0TJS'), findsOneWidget);

      await tester.ensureVisible(find.text('Провести продажу'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Провести продажу'));
      await tester.pumpAndSettle();

      expect(
        find.text('Для продажи абонемента укажите ID клиента.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).first, '11');
      await tester.ensureVisible(find.text('Провести продажу'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Провести продажу'));
      await tester.pumpAndSettle();

      expect(find.text('Потеряна связь'), findsOneWidget);
      expect(salesRepo.saleCalls.single.key, 'sale-key-1');

      await tester.ensureVisible(find.text('Провести продажу'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Провести продажу'));
      await tester.pumpAndSettle();

      expect(salesRepo.saleCalls.length, 2);
      expect(salesRepo.saleCalls[1].key, 'sale-key-1');
    },
  );

  testWidgets(
    'SalesHistoryTab and ProductsScreen restrict refund and product management to owner',
    (tester) async {
      final repo = _FakeSalesRepo();

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SalesHistoryTab(
                    repository: repo,
                    sessionController: _session(BusinessRole.admin),
                  ),
                  ProductsScreen(
                    repository: repo,
                    sessionController: _session(BusinessRole.admin),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Возврат'), findsNothing);
      expect(find.text('Добавить товар'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SalesHistoryTab(
                repository: repo,
                sessionController: _session(BusinessRole.owner),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Возврат'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Дубль чека');
      await tester.tap(find.text('Подтвердить возврат'));
      await tester.pumpAndSettle();

      expect(repo.lastRefund, (saleId: 70, reason: 'Дубль чека'));
      expect(find.text('Причина возврата: Дубль чека'), findsOneWidget);
    },
  );
}
