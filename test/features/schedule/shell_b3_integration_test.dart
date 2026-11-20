import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/analytics_billing/domain/analytics_and_billing_models.dart';
import 'package:ugym_business/features/analytics_billing/presentation/analytics_and_billing_screens.dart';
import 'package:ugym_business/features/schedule/domain/trainers_schedule_models.dart';
import 'package:ugym_business/features/schedule/presentation/schedule_tab.dart';
import 'package:ugym_business/features/schedule/presentation/trainers_screen.dart';
import 'package:ugym_business/features/storefront_staff/domain/storefront_and_staff_models.dart';
import 'package:ugym_business/features/storefront_staff/presentation/staff_management_screen.dart';
import 'package:ugym_business/features/storefront_staff/presentation/storefront_editor_screen.dart';
import 'package:ugym_business/main.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeScheduleRepo implements TrainersScheduleRepository {
  @override
  Future<List<TrainerProfile>> listTrainers({required int gymId}) async =>
      const [
        TrainerProfile(
          id: 3,
          publicId: '01t3',
          gymId: 10,
          name: 'Иван Петров',
          bio: 'Кроссфит',
          isActive: true,
        ),
      ];

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
  }) async => [
    ClassSession(
      id: 101,
      publicId: '01s101',
      gymId: gymId,
      templateId: 7,
      trainerId: 3,
      title: 'Йога',
      capacity: 15,
      bookedCount: 2,
      availableSeats: 13,
      startsAt: DateTime.utc(2026, 11, 18, 9, 0),
      endsAt: DateTime.utc(2026, 11, 18, 10, 0),
      status: ClassSessionStatus.scheduled,
    ),
  ];

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
        status: CompanySubscriptionStatus.active,
        isReadOnly: false,
        startsAt: DateTime.utc(2026, 11, 1),
        endsAt: DateTime.utc(2026, 12, 1),
      );
}

Future<BusinessSessionController> _createSession(BusinessRole role) async {
  final prefs = AppPreferences(storage: InMemoryTokenStorage());
  final session = BusinessSessionController(preferences: prefs)..setRole(role);
  await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
  return session;
}

void main() {
  testWidgets(
    'UgymBusinessApp wires owner B3 schedule, trainers, analytics, storefront, staff, announcements, and billing',
    (tester) async {
      final session = await _createSession(BusinessRole.owner);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        UgymBusinessApp(
          sessionController: session,
          trainersScheduleRepository: _FakeScheduleRepo(),
          storefrontAndStaffRepository: _FakeStorefrontStaffRepo(),
          analyticsAndBillingRepository: _FakeAnalyticsBillingRepo(),
        ),
      );
      await tester.pumpAndSettle();

      // Operations: schedule and trainers tabs.
      await tester.tap(find.text('Операции'));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleTab), findsOneWidget);
      expect(find.text('Йога'), findsOneWidget);

      await tester.tap(find.text('Тренеры'));
      await tester.pumpAndSettle();
      expect(find.byType(TrainersScreen), findsOneWidget);
      expect(find.text('Иван Петров'), findsOneWidget);

      await tester.tap(find.text('Расписание'));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleTab), findsOneWidget);

      // Analytics tab.
      await tester.tap(find.text('Аналитика'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsScreen), findsOneWidget);
      expect(find.text('Выручка: 500,00\u00a0TJS'), findsOneWidget);

      // More tab: storefront, staff, announcements, billing.
      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Витрина'));
      await tester.pumpAndSettle();
      expect(find.byType(StorefrontEditorScreen), findsOneWidget);
      expect(find.text('Витрина зала • Центр'), findsOneWidget);

      await tester.tap(find.text('Штат'));
      await tester.pumpAndSettle();
      expect(find.byType(StaffManagementScreen), findsOneWidget);
      expect(find.text('Алишер'), findsOneWidget);

      await tester.tap(find.text('Рассылки'));
      await tester.pumpAndSettle();
      expect(find.byType(AnnouncementsScreen), findsOneWidget);

      await tester.tap(find.text('Подписка'));
      await tester.pumpAndSettle();
      expect(find.byType(BillingStatusScreen), findsOneWidget);
      expect(find.text('Активна'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin sees announcements and billing in More, but not storefront, staff, or analytics',
    (tester) async {
      final session = await _createSession(BusinessRole.admin);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        UgymBusinessApp(
          sessionController: session,
          trainersScheduleRepository: _FakeScheduleRepo(),
          storefrontAndStaffRepository: _FakeStorefrontStaffRepo(),
          analyticsAndBillingRepository: _FakeAnalyticsBillingRepo(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Аналитика'), findsNothing);

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      expect(find.text('Витрина'), findsNothing);
      expect(find.text('Штат'), findsNothing);
      expect(find.text('Рассылки'), findsOneWidget);
      expect(find.text('Подписка'), findsOneWidget);

      await tester.tap(find.text('Подписка'));
      await tester.pumpAndSettle();
      expect(find.byType(BillingStatusScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Trainer sees ScheduleTab directly in Operations with bookings access and clean More tab',
    (tester) async {
      final session = await _createSession(BusinessRole.trainer);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        UgymBusinessApp(
          sessionController: session,
          trainersScheduleRepository: _FakeScheduleRepo(),
          storefrontAndStaffRepository: _FakeStorefrontStaffRepo(),
          analyticsAndBillingRepository: _FakeAnalyticsBillingRepo(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleTab), findsOneWidget);
      expect(find.text('Сканер QR клиента'), findsNothing);
      expect(find.text('Открыть кассу'), findsNothing);

      await tester.tap(find.text('Записавшиеся'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionBookingsScreen), findsOneWidget);
      expect(find.text('Клиент №42'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();
      expect(find.text('Витрина'), findsNothing);
      expect(find.text('Штат'), findsNothing);
      expect(find.text('Рассылки'), findsNothing);
      expect(find.text('Подписка'), findsNothing);
    },
  );
}
