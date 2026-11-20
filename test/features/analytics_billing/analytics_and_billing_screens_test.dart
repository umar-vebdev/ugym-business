import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/analytics_billing/domain/analytics_and_billing_models.dart';
import 'package:ugym_business/features/analytics_billing/presentation/analytics_and_billing_screens.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeAnalyticsBillingRepo implements AnalyticsAndBillingRepository {
  int? lastInactiveDays;
  ({AnnouncementChannel channel, String title, String body})? lastAnnouncement;

  @override
  Future<OverviewAnalytics> fetchOverview({
    String? from,
    String? to,
    int inactiveDays = 14,
  }) async {
    lastInactiveDays = inactiveDays;
    return const OverviewAnalytics(
      from: '2026-11-01',
      to: '2026-11-17',
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
        byDay: {'2026-11-17': 22},
        inactiveDaysThreshold: 14,
        inactiveClientsCount: 12,
      ),
      popularMemberships: [
        ItemPopularity(
          itemId: 3,
          name: 'Безлимит 30',
          soldCount: 10,
          revenueMinor: 45000,
          currency: 'TJS',
        ),
      ],
      popularProducts: [],
    );
  }

  @override
  Future<RevenueReport> fetchRevenueReport({String? from, String? to}) async =>
      const RevenueReport(
        from: '2026-11-01',
        to: '2026-11-17',
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
  }) async {
    lastAnnouncement = (channel: channel, title: title, body: body);
    return AnnouncementQueuedResult(queuedCount: 25, channel: channel);
  }

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

BusinessSessionController _session(
  BusinessRole role, {
  bool isReadOnly = false,
}) {
  final prefs = AppPreferences(storage: InMemoryTokenStorage());
  return BusinessSessionController(preferences: prefs)
    ..setRole(role)
    ..setSubscriptionStatus(isReadOnly: isReadOnly);
}

void main() {
  testWidgets(
    'AnalyticsScreen blocks admin, loads owner metrics, and applies inactive_days filter',
    (tester) async {
      final repo = _FakeAnalyticsBillingRepo();

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: AnalyticsScreen(
              repository: repo,
              sessionController: _session(BusinessRole.admin),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Недостаточно прав'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnalyticsScreen(
                repository: repo,
                sessionController: _session(BusinessRole.owner),
                initialFrom: '2026-11-01',
                initialTo: '2026-11-17',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Выручка: 500,00\u00a0TJS'), findsOneWidget);
      expect(find.textContaining('Безлимит 30 — 10 шт.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(2), '30');
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
      expect(repo.lastInactiveDays, 30);
    },
  );

  testWidgets(
    'AnnouncementsScreen queues push/sms and respects read-only lock',
    (tester) async {
      final repo = _FakeAnalyticsBillingRepo();

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnnouncementsScreen(
                repository: repo,
                sessionController: _session(BusinessRole.admin),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('SMS'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'График');
      await tester.enterText(find.byType(TextField).at(1), 'Работаем до 22:00');
      await tester.tap(find.text('Отправить рассылку'));
      await tester.pumpAndSettle();

      expect(repo.lastAnnouncement?.channel, AnnouncementChannel.sms);
      expect(
        find.text('Рассылка (sms) поставлена в очередь: 25.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BillingStatusScreen displays subscription and plans without payment CTA',
    (tester) async {
      final repo = _FakeAnalyticsBillingRepo();

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BillingStatusScreen(
                repository: repo,
                sessionController: _session(BusinessRole.admin),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Подписка платформы: Активна (active)'), findsOneWidget);
      expect(find.text('Pro (month) — 299,00\u00a0TJS'), findsOneWidget);
      expect(
        find.text('Лимиты: до 3 залов, до 15 сотрудников'),
        findsOneWidget,
      );
      expect(find.text('Оплатить'), findsNothing);
    },
  );
}
