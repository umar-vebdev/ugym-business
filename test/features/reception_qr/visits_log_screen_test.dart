import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';
import 'package:ugym_business/core/router/business_shell.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/theme_controller.dart';
import 'package:ugym_business/features/company_onboarding/domain/company_onboarding_models.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/features/reception_qr/presentation/visits_log_screen.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeVisitsRepository implements ReceptionVisitsRepository {
  List<VisitRecord> visits = <VisitRecord>[];
  final List<({int visitId, String reason})> cancelCalls =
      <({int visitId, String reason})>[];
  final List<
    ({
      int clientId,
      int gymId,
      DateTime? visitedAt,
      String? device,
      String? idempotencyKey,
    })
  >
  manualCalls =
      <
        ({
          int clientId,
          int gymId,
          DateTime? visitedAt,
          String? device,
          String? idempotencyKey,
        })
      >[];

  bool failNextManualCheckIn = false;

  @override
  Future<List<VisitRecord>> listCompanyVisits() async => visits;

  @override
  Future<VisitRecord> cancelVisit({
    required int visitId,
    required String reason,
  }) async {
    cancelCalls.add((visitId: visitId, reason: reason));
    final original = visits.firstWhere((v) => v.id == visitId);
    final updated = VisitRecord(
      id: original.id,
      companyId: original.companyId,
      gymId: original.gymId,
      clientId: original.clientId,
      membershipId: original.membershipId,
      method: original.method,
      status: VisitStatus.cancelled,
      visitedAt: original.visitedAt,
      visitDate: original.visitDate,
      cancelReason: reason,
    );
    visits = visits
        .map((v) => v.id == visitId ? updated : v)
        .toList(growable: false);
    return updated;
  }

  @override
  Future<CheckInResult> registerManualVisit({
    required int clientId,
    required int gymId,
    DateTime? visitedAt,
    String? device,
    String? idempotencyKey,
  }) async {
    manualCalls.add((
      clientId: clientId,
      gymId: gymId,
      visitedAt: visitedAt,
      device: device,
      idempotencyKey: idempotencyKey,
    ));
    if (failNextManualCheckIn) {
      failNextManualCheckIn = false;
      throw const UgymApiException(
        code: 'NETWORK_ERROR',
        message: 'Временный сбой сети',
      );
    }
    return CheckInResult(
      id: 99,
      companyId: 1,
      gymId: gymId,
      clientId: clientId,
      membershipId: 500,
      method: VisitMethod.manual,
      status: VisitStatus.completed,
      visitedAt: visitedAt ?? DateTime.utc(2026, 11, 17, 10, 0),
      visitDate: '2026-11-17',
      remainingVisits: 7,
    );
  }

  @override
  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GymQrToken> fetchGymQr({required int gymId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<VisitRecord>> listClientVisits({required int clientId}) {
    throw UnimplementedError();
  }
}

final class _FakeOnboardingRepository implements CompanyOnboardingRepository {
  @override
  Future<CreatedCompanyResult> createCompany({
    required String companyName,
    required String gymName,
    String? gymAddress,
  }) async {
    return const CreatedCompanyResult(companyId: 1, gymId: 10);
  }

  @override
  Future<GymBranch> createGym({
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CurrencyOption>> listCurrencies() async => const [
    CurrencyOption(id: 1, code: 'TJS', name: 'Somoni', symbol: 'SM'),
  ];

  @override
  Future<List<GymBranch>> listGyms() async => const [
    GymBranch(
      id: 10,
      companyId: 1,
      name: 'Центр',
      timezone: 'Asia/Dushanbe',
      geoCheckEnabled: false,
    ),
  ];

  @override
  Future<String> updateCompanyCurrency({required int currencyId}) async =>
      'TJS';

  @override
  Future<GymBranch> updateGym({
    required int gymId,
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  }) {
    throw UnimplementedError();
  }
}

BusinessSessionController _makeSession({
  required BusinessRole role,
  bool isReadOnly = false,
  List<GymSummary> gyms = const [GymSummary(id: 10, name: 'Центр')],
}) {
  final prefs = AppPreferences(storage: InMemoryTokenStorage());
  final session = BusinessSessionController(preferences: prefs);
  session.setRole(role);
  session.setSubscriptionStatus(isReadOnly: isReadOnly);
  if (gyms.isNotEmpty) {
    session.setGyms(gyms);
  }
  return session;
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: UcraftTheme.light(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets(
    'VisitsLogScreen enforces 24h cancellation window and requires reason',
    (tester) async {
      final nowUtc = DateTime.utc(2026, 11, 17, 12, 0);
      final repo = _FakeVisitsRepository()
        ..visits = [
          VisitRecord(
            id: 1,
            companyId: 1,
            gymId: 10,
            clientId: 42,
            membershipId: 101,
            method: VisitMethod.qr,
            status: VisitStatus.completed,
            visitedAt: nowUtc.subtract(const Duration(hours: 2)),
            visitDate: '2026-11-17',
          ),
          VisitRecord(
            id: 2,
            companyId: 1,
            gymId: 10,
            clientId: 43,
            membershipId: 102,
            method: VisitMethod.manual,
            status: VisitStatus.completed,
            visitedAt: nowUtc.subtract(const Duration(hours: 25)),
            visitDate: '2026-11-16',
          ),
        ];

      final session = _makeSession(role: BusinessRole.admin);

      await tester.pumpWidget(
        _wrap(
          VisitsLogScreen(
            repository: repo,
            sessionController: session,
            clock: () => nowUtc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Клиент №42 • Абонемент №101'), findsOneWidget);
      expect(find.text('Клиент №43 • Абонемент №102'), findsOneWidget);
      // Only the 2-hour-old visit can be cancelled; the 25-hour-old visit cannot.
      expect(find.text('Отменить визит'), findsOneWidget);

      await tester.ensureVisible(find.text('Отменить визит'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отменить визит'));
      await tester.pumpAndSettle();

      // Empty reason should trigger validation error.
      await tester.tap(find.text('Подтвердить отмену'));
      await tester.pumpAndSettle();
      expect(find.text('Укажите причину отмены.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'Ошибочная отметка');
      await tester.tap(find.text('Подтвердить отмену'));
      await tester.pumpAndSettle();

      expect(repo.cancelCalls.length, 1);
      expect(repo.cancelCalls.single.visitId, 1);
      expect(repo.cancelCalls.single.reason, 'Ошибочная отметка');
      expect(find.text('Причина отмены: Ошибочная отметка'), findsOneWidget);
      expect(find.text('Отменить визит'), findsNothing);
    },
  );

  testWidgets(
    'VisitsLogScreen disables mutations when subscription read-only',
    (tester) async {
      final nowUtc = DateTime.utc(2026, 11, 17, 12, 0);
      final repo = _FakeVisitsRepository()
        ..visits = [
          VisitRecord(
            id: 1,
            companyId: 1,
            gymId: 10,
            clientId: 42,
            membershipId: 101,
            method: VisitMethod.qr,
            status: VisitStatus.completed,
            visitedAt: nowUtc.subtract(const Duration(hours: 1)),
            visitDate: '2026-11-17',
          ),
        ];
      final session = _makeSession(role: BusinessRole.owner, isReadOnly: true);

      await tester.pumpWidget(
        _wrap(
          VisitsLogScreen(
            repository: repo,
            sessionController: session,
            clock: () => nowUtc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Отменить визит'), findsNothing);
      final manualButton = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Ручная отметка'),
      );
      expect(manualButton.onPressed, isNull);
    },
  );

  testWidgets(
    'ManualCheckInSheet supports backdated UTC visit and preserves Idempotency-Key on retry',
    (tester) async {
      final repo = _FakeVisitsRepository()..failNextManualCheckIn = true;
      int keyCounter = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: ManualCheckInSheet(
              repository: repo,
              gymId: 10,
              gymName: 'Центр',
              idempotencyKeyGenerator: () => 'key-${++keyCounter}',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, '42');
      await tester.tap(find.text('Отметить задним числом'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), '2026-11-16 14:30');
      await tester.ensureVisible(find.text('Отметить посещение'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отметить посещение'));
      await tester.pumpAndSettle();

      expect(find.text('Временный сбой сети'), findsOneWidget);
      expect(repo.manualCalls.length, 1);
      expect(repo.manualCalls.first.idempotencyKey, 'key-1');
      // 14:30 in Dushanbe (+05:00) == 09:30 UTC.
      expect(
        repo.manualCalls.first.visitedAt,
        DateTime.utc(2026, 11, 16, 9, 30),
      );

      // Retry without changing inputs must reuse key-1.
      await tester.ensureVisible(find.text('Отметить посещение'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отметить посещение'));
      await tester.pumpAndSettle();

      expect(repo.manualCalls.length, 2);
      expect(repo.manualCalls[1].idempotencyKey, 'key-1');
    },
  );

  testWidgets(
    'BusinessShell wires B1 onboarding, operations, and owner settings',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final localeController = LocaleController(preferences: prefs);
      final themeController = ThemeController(preferences: prefs);
      final onboardingRepo = _FakeOnboardingRepository();
      final visitsRepo = _FakeVisitsRepository();

      // 1. noCompany -> shows CompanyOnboardingCard on overview.
      final noCompanySession = _makeSession(
        role: BusinessRole.noCompany,
        gyms: const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: BusinessShell(
            config: const AppConfig.dev(),
            sessionController: noCompanySession,
            localeController: localeController,
            themeController: themeController,
            onboardingRepository: onboardingRepo,
            visitsRepository: visitsRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Создание компании (14 дней бесплатно)'),
        findsOneWidget,
      );

      // 2. owner -> operations tab shows scanner, kiosk, and visits log; more shows branches/currency.
      final ownerSession = _makeSession(role: BusinessRole.owner);
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: BusinessShell(
            config: const AppConfig.dev(),
            sessionController: ownerSession,
            localeController: localeController,
            themeController: themeController,
            onboardingRepository: onboardingRepo,
            visitsRepository: visitsRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Операции'));
      await tester.pumpAndSettle();
      expect(find.text('Сканер QR клиента'), findsOneWidget);
      expect(find.text('Киоск QR зала'), findsOneWidget);
      expect(find.text('Журнал визитов'), findsOneWidget);

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();
      expect(find.text('Добавить филиал'), findsWidgets);
      expect(find.text('Валюта компании'), findsOneWidget);
    },
  );
}
