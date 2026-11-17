import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';
import 'package:ugym_business/core/router/business_shell.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/theme_controller.dart';
import 'package:ugym_business/features/clients/domain/clients_models.dart';
import 'package:ugym_business/features/clients/presentation/client_detail_screen.dart';
import 'package:ugym_business/features/memberships/domain/memberships_models.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/features/sales/domain/sales_and_requests_models.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeClientsRepo implements ClientsRepository {
  @override
  Future<ClientsPage> listClients({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async => const ClientsPage(
    items: [
      ClientSummary(
        id: 11,
        name: 'Фарход',
        phone: '+992900001122',
        email: 'farhod@gym.tj',
        linked: true,
      ),
    ],
    page: 1,
    perPage: 20,
    total: 1,
  );

  @override
  Future<int> createClient({
    required String name,
    required String phone,
    String? email,
  }) => throw UnimplementedError();

  @override
  Future<bool> mergeClients({required int sourceId, required int targetId}) =>
      throw UnimplementedError();
}

final class _FakeMembershipsRepo implements MembershipsRepository {
  @override
  Future<List<ClientMembership>> listClientMemberships({
    required int clientId,
  }) async => const [
    ClientMembership(
      id: 51,
      clientId: 11,
      typeId: 3,
      kind: MembershipKind.unlimitedTime,
      status: MembershipStatus.active,
      remainingVisits: 10,
    ),
  ];

  @override
  Future<List<ClientMembership>> listExpiringMemberships() async => const [];

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
  Future<bool> setMembershipTypeActive({
    required int typeId,
    required bool isActive,
  }) => throw UnimplementedError();

  @override
  Future<MembershipFreezeState> unfreezeMembership({
    required int membershipId,
  }) => throw UnimplementedError();
}

final class _FakeVisitsRepo implements ReceptionVisitsRepository {
  @override
  Future<List<VisitRecord>> listClientVisits({required int clientId}) async => [
    VisitRecord(
      id: 9,
      companyId: 1,
      gymId: 10,
      clientId: clientId,
      membershipId: 51,
      method: VisitMethod.qr,
      status: VisitStatus.completed,
      visitedAt: DateTime.utc(2026, 11, 17, 10, 0),
      visitDate: '2026-11-17',
    ),
  ];

  @override
  Future<List<VisitRecord>> listCompanyVisits() async => const [];

  @override
  Future<VisitRecord> cancelVisit({
    required int visitId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<GymQrToken> fetchGymQr({required int gymId}) =>
      throw UnimplementedError();

  @override
  Future<CheckInResult> registerManualVisit({
    required int clientId,
    required int gymId,
    DateTime? visitedAt,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();
}

final class _FakeSalesRepo implements SalesAndRequestsRepository {
  @override
  Future<List<SaleRecord>> listClientSales({required int clientId}) async => [
    SaleRecord(
      id: 70,
      companyId: 1,
      clientId: clientId,
      status: SaleStatus.paid,
      paymentMethod: PaymentMethod.cash,
      totalMinor: 25000,
      currency: 'TJS',
      acceptedByUserId: 2,
      paidAt: DateTime.utc(2026, 11, 17, 9, 0),
      items: const [],
    ),
  ];

  @override
  Future<List<MembershipRequestRecord>> listMembershipRequests({
    MembershipRequestStatus? status,
  }) async => const [];

  @override
  Future<List<ProductItem>> listProducts({bool? onlyActive}) async => const [];

  @override
  Future<List<SaleRecord>> listSales() async => const [];

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
  Future<PayRequestResult> payMembershipRequest({
    required int requestId,
    required PaymentMethod paymentMethod,
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<SaleRecord> refundSale({
    required int saleId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<SaleRecord> registerSale({
    int? clientId,
    required PaymentMethod paymentMethod,
    List<SaleProductLineInput> products = const <SaleProductLineInput>[],
    List<int> membershipTypeIds = const <int>[],
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<ProductItem> updateProduct({
    required int productId,
    bool? isActive,
    int? stockQuantity,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'BusinessShell wires B2 members, ClientDetailScreen 360, and POS operations',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(preferences: prefs)
        ..setRole(BusinessRole.owner);
      await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: BusinessShell(
            config: const AppConfig.dev(),
            sessionController: session,
            localeController: LocaleController(preferences: prefs),
            themeController: ThemeController(preferences: prefs),
            clientsRepository: _FakeClientsRepo(),
            membershipsRepository: _FakeMembershipsRepo(),
            visitsRepository: _FakeVisitsRepo(),
            salesRepository: _FakeSalesRepo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Operations tab: POS button and B2 sub-tabs visible for owner.
      await tester.tap(find.text('Операции'));
      await tester.pumpAndSettle();
      expect(find.text('Открыть кассу'), findsOneWidget);
      expect(find.text('Заявки'), findsOneWidget);
      expect(find.text('Продажи'), findsOneWidget);
      expect(find.text('Товары'), findsOneWidget);

      // Members tab: clients list -> open ClientDetailScreen 360.
      await tester.tap(find.text('Клиенты'));
      await tester.pumpAndSettle();
      expect(find.text('Фарход (#11)'), findsOneWidget);

      await tester.tap(find.text('Фарход (#11)'));
      await tester.pumpAndSettle();

      expect(find.byType(ClientDetailScreen), findsOneWidget);
      expect(find.text('Абонемент №51 • active'), findsOneWidget);

      await tester.tap(find.text('Посещения'));
      await tester.pumpAndSettle();
      expect(find.text('Визит №9 • completed'), findsOneWidget);

      await tester.tap(find.text('Покупки/Чеки'));
      await tester.pumpAndSettle();
      expect(find.text('Чек №70 • 250.00 TJS'), findsOneWidget);
    },
  );

  testWidgets('Trainer does not see POS checkout or sales tabs in operations', (
    tester,
  ) async {
    final prefs = AppPreferences(storage: InMemoryTokenStorage());
    final session = BusinessSessionController(preferences: prefs)
      ..setRole(BusinessRole.trainer);
    await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);

    await tester.pumpWidget(
      MaterialApp(
        theme: UcraftTheme.light(),
        home: BusinessShell(
          config: const AppConfig.dev(),
          sessionController: session,
          localeController: LocaleController(preferences: prefs),
          themeController: ThemeController(preferences: prefs),
          visitsRepository: _FakeVisitsRepo(),
          salesRepository: _FakeSalesRepo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Открыть кассу'), findsNothing);
    expect(find.text('Заявки'), findsNothing);
    expect(find.text('Журнал визитов'), findsOneWidget);
  });
}
