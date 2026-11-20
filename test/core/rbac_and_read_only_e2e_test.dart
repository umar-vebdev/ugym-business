import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/network/business_api_client.dart';
import 'package:ugym_business/core/router/role_guard_and_banners.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/analytics_billing/domain/analytics_and_billing_models.dart';
import 'package:ugym_business/features/analytics_billing/presentation/analytics_and_billing_screens.dart';
import 'package:ugym_business/features/clients/domain/clients_models.dart';
import 'package:ugym_business/features/clients/presentation/client_detail_screen.dart';
import 'package:ugym_business/features/memberships/data/remote_memberships_repository.dart';
import 'package:ugym_business/features/memberships/domain/memberships_models.dart';
import 'package:ugym_business/features/reception_qr/data/remote_reception_visits_repository.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/features/sales/data/remote_sales_and_requests_repository.dart';
import 'package:ugym_business/features/sales/domain/sales_and_requests_models.dart';
import 'package:ugym_business/features/schedule/domain/trainers_schedule_models.dart';
import 'package:ugym_business/features/schedule/presentation/schedule_tab.dart';
import 'package:ugym_business/features/storefront_staff/domain/storefront_and_staff_models.dart';
import 'package:ugym_business/main.dart';
import 'package:ugym_core/ugym_core.dart';

final class _MockHttpAdapter implements HttpClientAdapter {
  _MockHttpAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int statusCode, Map<String, Object?> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

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
  Future<List<VisitRecord>> listClientVisits({required int clientId}) async =>
      const [];

  @override
  Future<List<VisitRecord>> listCompanyVisits() async => [
    VisitRecord(
      id: 9,
      companyId: 1,
      gymId: 10,
      clientId: 11,
      membershipId: 51,
      method: VisitMethod.qr,
      status: VisitStatus.completed,
      visitedAt: DateTime.utc(2026, 11, 18, 9, 0),
      visitDate: '2026-11-18',
    ),
  ];

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
  Future<List<SaleRecord>> listClientSales({required int clientId}) async =>
      const [];

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

final class _FakeScheduleRepo implements TrainersScheduleRepository {
  @override
  Future<List<TrainerProfile>> listTrainers({required int gymId}) async =>
      const [];

  @override
  Future<TrainerProfile> createTrainer({
    required int gymId,
    required String name,
    String? bio,
  }) => throw UnimplementedError();

  @override
  Future<TrainerProfile> updateTrainer({
    required int trainerId,
    required String name,
    String? bio,
    bool? isActive,
  }) => throw UnimplementedError();

  @override
  Future<List<ScheduleTemplate>> listTemplates({
    required int gymId,
    bool? onlyActive,
  }) async => const [];

  @override
  Future<ScheduleTemplate> createTemplate({
    required int gymId,
    required int trainerId,
    required String title,
    String? description,
    required int weekday,
    required int startTimeMinute,
    required int durationMinutes,
    required int capacity,
  }) => throw UnimplementedError();

  @override
  Future<ScheduleTemplate> updateTemplate({
    required int templateId,
    required int trainerId,
    required String title,
    String? description,
    required int weekday,
    required int startTimeMinute,
    required int durationMinutes,
    required int capacity,
    bool? isActive,
  }) => throw UnimplementedError();

  @override
  Future<List<ClassSession>> listSessions({
    required int gymId,
    required String fromDate,
    required String toDate,
  }) async => const [];

  @override
  Future<List<ClassSession>> generateSessions({
    required int gymId,
    required String fromDate,
    required String toDate,
  }) => throw UnimplementedError();

  @override
  Future<ClassSession> cancelSession({required int sessionId}) =>
      throw UnimplementedError();

  @override
  Future<List<ClassBooking>> listSessionBookings({
    required int sessionId,
  }) async => [
    ClassBooking(
      id: 500,
      publicId: '01b500',
      companyId: 1,
      gymId: 10,
      sessionId: sessionId,
      clientId: 42,
      status: ClassBookingStatus.booked,
      bookedAt: DateTime.utc(2026, 11, 17, 10, 0),
    ),
  ];
}

final class _FakeStorefrontStaffRepo implements StorefrontAndStaffRepository {
  @override
  Future<List<StaffMember>> listStaff() async => const [
    StaffMember(
      id: 2,
      userId: 20,
      companyId: 1,
      role: StaffRoleValue.admin,
      name: 'Алишер',
      email: 'alisher@gym.tj',
    ),
  ];

  @override
  Future<StaffMember> inviteStaff({
    required String email,
    required StaffRoleValue role,
  }) => throw UnimplementedError();

  @override
  Future<StaffMember> updateStaffRole({
    required int staffId,
    required StaffRoleValue role,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteStaff({required int staffId}) =>
      throw UnimplementedError();

  @override
  Future<GymProfile> updateGymProfile({
    required int gymId,
    required GymProfileInput input,
  }) => throw UnimplementedError();

  @override
  Future<GymProfile> submitGymProfile({required int gymId}) =>
      throw UnimplementedError();

  @override
  Future<GymProfile> setGymPublication({
    required int gymId,
    required bool isPublic,
  }) => throw UnimplementedError();

  @override
  Future<GymPhoto> uploadGymPhoto({
    required int gymId,
    required List<int> bytes,
    required String filename,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteGymPhoto({required int gymId, required int photoId}) =>
      throw UnimplementedError();
}

final class _FakeAnalyticsBillingRepo implements AnalyticsAndBillingRepository {
  @override
  Future<OverviewAnalytics> fetchOverview({
    String? from,
    String? to,
    int inactiveDays = 14,
  }) async => const OverviewAnalytics(
    from: '2026-11-11',
    to: '2026-11-18',
    revenue: RevenueSummary(
      totalMinor: 50000,
      membershipsMinor: 45000,
      productsMinor: 5000,
      byPaymentMethod: RevenueByPaymentMethod(
        cash: 30000,
        cardTerminal: 15000,
        transfer: 5000,
      ),
      salesCount: 4,
      currency: 'TJS',
    ),
    clients: ClientsAnalyticsSummary(
      totalClients: 120,
      newClients: 15,
      existingClients: 105,
    ),
    visits: VisitsAnalyticsSummary(
      totalVisits: 240,
      qrVisits: 220,
      manualVisits: 20,
      byDay: {'2026-11-18': 22},
      inactiveDaysThreshold: 14,
      inactiveClientsCount: 12,
    ),
    popularMemberships: [],
    popularProducts: [],
  );

  @override
  Future<RevenueReport> fetchRevenueReport({String? from, String? to}) async =>
      const RevenueReport(
        from: '2026-11-11',
        to: '2026-11-18',
        summary: RevenueSummary(
          totalMinor: 50000,
          membershipsMinor: 45000,
          productsMinor: 5000,
          byPaymentMethod: RevenueByPaymentMethod(
            cash: 30000,
            cardTerminal: 15000,
            transfer: 5000,
          ),
          salesCount: 4,
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
  Future<List<PlatformPlan>> listBillingPlans() async => const [
    PlatformPlan(
      id: 1,
      name: 'Pro',
      period: BillingPlanPeriod.month,
      priceMinor: 29900,
      currency: 'TJS',
      maxGyms: 3,
      maxStaff: 15,
      isActive: true,
    ),
  ];

  @override
  Future<CompanySubscription> fetchBillingSubscription() async =>
      CompanySubscription(
        id: 9,
        companyId: 1,
        planId: 1,
        status: CompanySubscriptionStatus.expired,
        isReadOnly: true,
        startsAt: DateTime.utc(2026, 10, 1),
        endsAt: DateTime.utc(2026, 11, 1),
      );
}

void main() {
  testWidgets(
    'Read-only mode opens BillingStatusScreen from banner and blocks all mutations while keeping reads active',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
        initialReadOnly: true,
      );
      await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        UgymBusinessApp(
          sessionController: session,
          visitsRepository: _FakeVisitsRepo(),
          clientsRepository: _FakeClientsRepo(),
          membershipsRepository: _FakeMembershipsRepo(),
          salesRepository: _FakeSalesRepo(),
          trainersScheduleRepository: _FakeScheduleRepo(),
          storefrontAndStaffRepository: _FakeStorefrontStaffRepo(),
          analyticsAndBillingRepository: _FakeAnalyticsBillingRepo(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionReadOnlyBanner), findsOneWidget);
      expect(
        find.text('Подписка истекла — доступен только просмотр'),
        findsOneWidget,
      );
      expect(find.widgetWithText(UcraftButton, 'Подробнее'), findsOneWidget);

      // Operations: reads work, POS & scanner & manual check-in blocked.
      await tester.tap(find.text('Операции'));
      await tester.pumpAndSettle();

      expect(find.text('Клиент №11 • Абонемент №51'), findsOneWidget);
      expect(find.text('Открыть кассу'), findsNothing);
      final scanButton = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Сканер QR клиента'),
      );
      final manualButton = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Ручная отметка'),
      );
      expect(scanButton.onPressed, isNull);
      expect(manualButton.onPressed, isNull);

      // Clients & ClientDetailScreen: reads work, add/merge/sell/freeze locked.
      await tester.tap(find.text('Клиенты'));
      await tester.pumpAndSettle();

      expect(find.text('Фарход (#11)'), findsOneWidget);
      expect(find.text('Объединить дубли'), findsNothing);
      final addClientBtn = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Добавить клиента'),
      );
      expect(addClientBtn.onPressed, isNull);

      await tester.tap(find.text('Фарход (#11)'));
      await tester.pumpAndSettle();

      expect(find.byType(ClientDetailScreen), findsOneWidget);
      expect(find.byType(SubscriptionReadOnlyBanner), findsOneWidget);
      expect(find.text('Абонемент №51 • active'), findsOneWidget);
      expect(find.text('Продать абонемент / товар'), findsNothing);
      expect(find.text('Заморозить'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Analytics: reads remain available in read-only mode.
      await tester.tap(find.text('Аналитика'));
      await tester.pumpAndSettle();
      expect(find.text('Выручка: 500,00\u00a0TJS'), findsOneWidget);

      // More -> Storefront & Staff mutations locked.
      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Витрина'));
      await tester.pumpAndSettle();
      final saveStorefrontBtn = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Сохранить витрину'),
      );
      expect(saveStorefrontBtn.onPressed, isNull);

      await tester.tap(find.text('Штат'));
      await tester.pumpAndSettle();
      expect(find.text('Алишер'), findsOneWidget);
      expect(find.text('Сделать тренером'), findsNothing);
      expect(find.text('Удалить'), findsNothing);
      final inviteStaffBtn = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Добавить в штат'),
      );
      expect(inviteStaffBtn.onPressed, isNull);

      // Banner "Подробнее" navigates straight to BillingStatusScreen.
      await tester.ensureVisible(
        find.widgetWithText(UcraftButton, 'Подробнее'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(UcraftButton, 'Подробнее'));
      await tester.pumpAndSettle();

      expect(find.byType(BillingStatusScreen), findsOneWidget);
      expect(
        find.text('Подписка платформы: Истекла (expired)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '403 SUBSCRIPTION_EXPIRED via BusinessApiClient reactively locks ClientDetailScreen',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
      );
      await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
      addTearDown(session.dispose);

      final apiClient = BusinessApiClient(
        config: const AppConfig.dev(),
        tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
        onSubscriptionExpired: session.markSubscriptionExpired,
      );
      apiClient.httpClient.dio.httpClientAdapter = _MockHttpAdapter((
        options,
      ) async {
        if (options.path == '/business/clients/11/memberships') {
          return _json(200, <String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'id': 51,
                'client_id': 11,
                'type_id': 3,
                'kind': 'unlimited_time',
                'status': 'active',
                'remaining_visits': 10,
              },
            ],
          });
        }
        if (options.path == '/business/clients/11/visits' ||
            options.path == '/business/clients/11/sales') {
          return _json(200, <String, Object?>{'data': <Object?>[]});
        }
        if (options.path == '/business/memberships/51/freeze') {
          return _json(403, <String, Object?>{
            'error': <String, Object?>{
              'code': 'SUBSCRIPTION_EXPIRED',
              'message': 'Подписка компании истекла.',
            },
          });
        }
        return _json(404, <String, Object?>{});
      });

      const client = ClientSummary(
        id: 11,
        name: 'Фарход',
        phone: '+992900001122',
        linked: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: ClientDetailScreen(
            client: client,
            sessionController: session,
            membershipsRepository: RemoteMembershipsRepository(
              httpClient: apiClient.httpClient,
            ),
            visitsRepository: RemoteReceptionVisitsRepository(
              httpClient: apiClient.httpClient,
            ),
            salesRepository: RemoteSalesAndRequestsRepository(
              httpClient: apiClient.httpClient,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Подписка истекла — доступен только просмотр'),
        findsNothing,
      );
      expect(find.text('Продать абонемент / товар'), findsOneWidget);
      expect(find.text('Заморозить'), findsOneWidget);

      await tester.tap(find.text('Заморозить'));
      await tester.pumpAndSettle();

      expect(session.isReadOnly, isTrue);
      expect(
        find.text('Подписка истекла — доступен только просмотр'),
        findsOneWidget,
      );
      expect(find.text('Продать абонемент / товар'), findsNothing);
      expect(find.text('Заморозить'), findsNothing);
    },
  );

  test('Trainer restores saved gym on bootstrapFromApi when /business/gyms returns 403', () async {
    final prefs = AppPreferences(storage: InMemoryTokenStorage());
    await prefs.writeSelectedGymId(15);
    await prefs.writeSelectedGymTimezone('Asia/Dushanbe');

    final bootstrappedSession = BusinessSessionController(preferences: prefs);
    addTearDown(bootstrappedSession.dispose);

    final client = UgymHttpClient(
      baseUrl: 'https://api.ugym.tj/api/v1',
      tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
    );
    client.dio.httpClientAdapter = _MockHttpAdapter(
      (_) async => _json(403, <String, Object?>{
        'error': <String, Object?>{'code': 'FORBIDDEN', 'message': 'Forbidden'},
      }),
    );

    final role = await bootstrappedSession.bootstrapFromApi(
      client,
      isTrainerHint: true,
    );
    expect(role, BusinessRole.trainer);
    expect(bootstrappedSession.selectedGym?.id, 15);
    expect(bootstrappedSession.selectedGym?.name, 'Филиал #15');
  });

  testWidgets('Trainer opens bookings by session ID when gym is unset', (
    tester,
  ) async {
    final unsetPrefs = AppPreferences(storage: InMemoryTokenStorage());
    final trainerSession = BusinessSessionController(
      preferences: unsetPrefs,
      initialRole: BusinessRole.trainer,
    );
    addTearDown(trainerSession.dispose);

    await tester.pumpWidget(
      UgymBusinessApp(
        sessionController: trainerSession,
        trainersScheduleRepository: _FakeScheduleRepo(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleTab), findsOneWidget);
    expect(find.text('Список группы по занятию'), findsOneWidget);

    await tester.tap(find.text('Открыть список группы'));
    await tester.pumpAndSettle();
    expect(find.text('Введите корректный ID занятия.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('trainer_session_id_input')),
      '101',
    );
    await tester.tap(find.text('Открыть список группы'));
    await tester.pumpAndSettle();

    expect(find.byType(SessionBookingsScreen), findsOneWidget);
    expect(find.text('Занятие №101'), findsOneWidget);
    expect(find.text('Записей в списке: 1'), findsOneWidget);
    expect(find.text('Клиент №42'), findsOneWidget);
  });
}
