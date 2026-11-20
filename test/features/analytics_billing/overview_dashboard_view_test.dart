import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/business_theme.dart';
import 'package:ugym_business/features/analytics_billing/domain/analytics_and_billing_models.dart';
import 'package:ugym_business/features/analytics_billing/presentation/analytics_and_billing_screens.dart';
import 'package:ugym_business/features/analytics_billing/presentation/overview_dashboard_view.dart';
import 'package:ugym_business/features/memberships/domain/memberships_models.dart';
import 'package:ugym_business/features/memberships/presentation/memberships_screens.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/features/sales/domain/sales_and_requests_models.dart';
import 'package:ugym_business/features/sales/presentation/membership_requests_and_sales_tabs.dart';
import 'package:ugym_business/main.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeAnalyticsRepo implements AnalyticsAndBillingRepository {
  int fetchOverviewCalls = 0;
  bool shouldFail = false;

  @override
  Future<OverviewAnalytics> fetchOverview({
    String? from,
    String? to,
    int inactiveDays = 14,
  }) async {
    fetchOverviewCalls++;
    if (shouldFail) {
      throw const UgymApiException(
        code: 'SERVER_ERROR',
        message: 'Сервер временно недоступен.',
        statusCode: 503,
      );
    }
    return const OverviewAnalytics(
      from: '2026-11-19',
      to: '2026-11-19',
      revenue: RevenueSummary(
        totalMinor: 125000,
        membershipsMinor: 100000,
        productsMinor: 25000,
        byPaymentMethod: RevenueByPaymentMethod(
          cash: 75000,
          cardTerminal: 50000,
          transfer: 0,
        ),
        salesCount: 5,
        currency: 'TJS',
      ),
      clients: ClientsAnalyticsSummary(
        totalClients: 90,
        newClients: 3,
        existingClients: 87,
      ),
      visits: VisitsAnalyticsSummary(
        totalVisits: 42,
        qrVisits: 38,
        manualVisits: 4,
        byDay: {'2026-11-19': 42},
        inactiveDaysThreshold: 14,
        inactiveClientsCount: 8,
      ),
      popularMemberships: [],
      popularProducts: [],
    );
  }

  @override
  Future<RevenueReport> fetchRevenueReport({String? from, String? to}) async =>
      const RevenueReport(
        from: '2026-11-19',
        to: '2026-11-19',
        summary: RevenueSummary(
          totalMinor: 125000,
          membershipsMinor: 100000,
          productsMinor: 25000,
          byPaymentMethod: RevenueByPaymentMethod(
            cash: 75000,
            cardTerminal: 50000,
            transfer: 0,
          ),
          salesCount: 5,
          currency: 'TJS',
        ),
      );

  @override
  Future<AnnouncementQueuedResult> sendAnnouncement({
    required AnnouncementChannel channel,
    required String title,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<List<PlatformPlan>> listBillingPlans() async => const [];

  @override
  Future<CompanySubscription> fetchBillingSubscription() =>
      throw UnimplementedError();
}

final class _FakeSalesRepo implements SalesAndRequestsRepository {
  bool shouldFail = false;

  @override
  Future<List<MembershipRequestRecord>> listMembershipRequests({
    MembershipRequestStatus? status,
  }) async {
    if (shouldFail) {
      throw const UgymApiException(
        code: 'NETWORK_ERROR',
        message: 'Нет соединения.',
        isNetworkError: true,
      );
    }
    return [
      MembershipRequestRecord(
        id: 1,
        companyId: 1,
        gymId: 10,
        userId: 5,
        membershipTypeId: 3,
        status: MembershipRequestStatus.pending,
        expiresAt: DateTime.utc(2026, 11, 20, 12, 0),
      ),
      MembershipRequestRecord(
        id: 2,
        companyId: 1,
        gymId: 10,
        userId: 6,
        membershipTypeId: 3,
        status: MembershipRequestStatus.pending,
        expiresAt: DateTime.utc(2026, 11, 20, 14, 0),
      ),
    ];
  }

  @override
  Future<List<ProductItem>> listProducts({bool? onlyActive}) async => const [];

  @override
  Future<List<SaleRecord>> listSales() async => const [];

  @override
  Future<List<SaleRecord>> listClientSales({required int clientId}) async =>
      const [];

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

final class _FakeMembershipsRepo implements MembershipsRepository {
  bool shouldFail = false;

  @override
  Future<List<ClientMembership>> listExpiringMemberships() async {
    if (shouldFail) {
      throw const UgymApiException(
        code: 'NETWORK_ERROR',
        message: 'Нет соединения.',
        isNetworkError: true,
      );
    }
    return [
      ClientMembership(
        id: 77,
        clientId: 11,
        typeId: 3,
        kind: MembershipKind.unlimitedTime,
        status: MembershipStatus.active,
        endsAt: DateTime.utc(2026, 11, 22, 12, 0),
      ),
    ];
  }

  @override
  Future<List<MembershipType>> listMembershipTypes({bool? onlyActive}) async =>
      const [];

  @override
  Future<List<ClientMembership>> listClientMemberships({
    required int clientId,
  }) async => const [];

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
  Future<List<VisitRecord>> listCompanyVisits() async => const [];

  @override
  Future<List<VisitRecord>> listClientVisits({required int clientId}) async =>
      const [];

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

void main() {
  testWidgets(
    'Owner sees daily KPIs, operational alerts, and navigates to requests, expiring, and analytics',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
      );
      await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
      addTearDown(session.dispose);

      final analyticsRepo = _FakeAnalyticsRepo();
      final salesRepo = _FakeSalesRepo();
      final membershipsRepo = _FakeMembershipsRepo();

      await tester.pumpWidget(
        UgymBusinessApp(
          sessionController: session,
          visitsRepository: _FakeVisitsRepo(),
          salesRepository: salesRepo,
          membershipsRepository: membershipsRepo,
          analyticsAndBillingRepository: analyticsRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(analyticsRepo.fetchOverviewCalls, 1);
      expect(find.text('Выручка сегодня'), findsOneWidget);
      expect(find.text('1\u00a0250,00\u00a0TJS'), findsOneWidget);
      expect(find.text('Посещения сегодня'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Заявки в ожидании'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Истекают за 7 дней'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Jump directly to pending requests tab.
      await tester.ensureVisible(find.text('К заявкам'));
      await tester.tap(find.text('К заявкам'));
      await tester.pumpAndSettle();
      expect(find.byType(MembershipRequestsQueueTab), findsOneWidget);

      // Return to overview and jump to expiring memberships.
      await tester.tap(find.text('Обзор'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('К истекающим'));
      await tester.tap(find.text('К истекающим'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpiringMembershipsTab), findsOneWidget);

      // Return to overview and jump to analytics.
      await tester.tap(find.text('Обзор'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Открыть аналитику'));
      await tester.tap(find.text('Открыть аналитику'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Admin sees operational counters without calling owner analytics endpoint',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.admin,
      );
      await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
      addTearDown(session.dispose);

      final analyticsRepo = _FakeAnalyticsRepo();

      await tester.pumpWidget(
        UgymBusinessApp(
          sessionController: session,
          visitsRepository: _FakeVisitsRepo(),
          salesRepository: _FakeSalesRepo(),
          membershipsRepository: _FakeMembershipsRepo(),
          analyticsAndBillingRepository: analyticsRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(analyticsRepo.fetchOverviewCalls, 0);
      expect(find.text('Выручка сегодня'), findsNothing);
      expect(find.text('Посещения сегодня'), findsNothing);
      expect(find.text('Заявки в ожидании'), findsOneWidget);
      expect(find.text('Истекают за 7 дней'), findsOneWidget);
      expect(find.text('Сканер QR клиента'), findsOneWidget);
      expect(find.text('Открыть кассу'), findsOneWidget);
    },
  );

  testWidgets(
    'OverviewDashboardView handles read-only restrictions and retries on error',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
        initialReadOnly: true,
      );
      await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
      addTearDown(session.dispose);

      final analyticsRepo = _FakeAnalyticsRepo()..shouldFail = true;
      final salesRepo = _FakeSalesRepo()..shouldFail = true;
      final membershipsRepo = _FakeMembershipsRepo()..shouldFail = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: OverviewDashboardView(
                sessionController: session,
                analyticsRepository: analyticsRepo,
                salesRepository: salesRepo,
                membershipsRepository: membershipsRepo,
                onOpenScanner: () {},
                onOpenPos: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read-only locks scanner and hides POS quick action.
      final scanBtn = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Сканер QR клиента'),
      );
      expect(scanBtn.onPressed, isNull);
      expect(find.text('Открыть кассу'), findsNothing);

      // Shows error state and recovers on retry.
      expect(find.text('Ошибка загрузки сводки'), findsOneWidget);
      analyticsRepo.shouldFail = false;
      salesRepo.shouldFail = false;
      membershipsRepo.shouldFail = false;

      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('1\u00a0250,00\u00a0TJS'), findsOneWidget);
      expect(find.text('Заявки в ожидании'), findsOneWidget);
    },
  );

  testWidgets(
    'OverviewDashboardView follows uCraft 1.1: single highlight hero card, single Primary CTA, status pill, and UcraftListSection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
      );
      await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: BusinessTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: OverviewDashboardView(
                sessionController: session,
                analyticsRepository: _FakeAnalyticsRepo(),
                salesRepository: _FakeSalesRepo(),
                membershipsRepository: _FakeMembershipsRepo(),
                onOpenScanner: () {},
                onOpenKiosk: () {},
                onOpenPos: () {},
                onOpenPendingRequests: () {},
                onOpenExpiringMemberships: () {},
                onOpenAnalytics: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 1 hero highlight card and 1 UcraftListSection with 2 UcraftListRow items.
      final heroCards = tester
          .widgetList<UcraftCard>(find.byType(UcraftCard))
          .where((c) => c.variant == UcraftCardVariant.highlight)
          .toList();
      expect(heroCards, hasLength(1));
      expect(find.byType(UcraftStatusPill), findsOneWidget);
      expect(find.byType(UcraftListSection), findsOneWidget);
      expect(find.byType(UcraftListRow), findsNWidgets(2));

      // Exactly 1 Primary UcraftButton visible on screen.
      final primaryButtons = tester
          .widgetList<UcraftButton>(find.byType(UcraftButton))
          .where((b) => b.variant == UcraftButtonVariant.primary)
          .toList();
      expect(primaryButtons, hasLength(1));
      expect(primaryButtons.single.label, 'Сканер QR клиента');
      expect(primaryButtons.single.fullWidth, isTrue);
      expect(
        tester.getBottomLeft(find.text('Открыть кассу')).dy,
        lessThan(510),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
