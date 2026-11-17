import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/schedule/domain/trainers_schedule_models.dart';
import 'package:ugym_business/features/schedule/presentation/schedule_tab.dart';
import 'package:ugym_business/features/schedule/presentation/trainers_screen.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeScheduleRepo implements TrainersScheduleRepository {
  List<TrainerProfile> trainers = const [
    TrainerProfile(
      id: 3,
      publicId: '01t3',
      gymId: 10,
      name: 'Иван Петров',
      bio: 'Кроссфит',
      isActive: true,
    ),
  ];

  List<ScheduleTemplate> templates = const [
    ScheduleTemplate(
      id: 7,
      publicId: '01tmpl7',
      gymId: 10,
      trainerId: 3,
      title: 'Йога',
      weekday: 1,
      startTimeMinute: 540,
      durationMinutes: 60,
      capacity: 15,
      isActive: true,
    ),
  ];

  List<ClassSession> sessions = [
    ClassSession(
      id: 101,
      publicId: '01s101',
      gymId: 10,
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

  List<ClassBooking> bookings = [
    ClassBooking(
      id: 500,
      publicId: '01b500',
      companyId: 1,
      gymId: 10,
      sessionId: 101,
      clientId: 42,
      status: ClassBookingStatus.booked,
      bookedAt: DateTime.utc(2026, 11, 17, 10, 0),
    ),
  ];

  ({int gymId, String fromDate, String toDate})? lastGenerated;
  int? lastCancelledSessionId;

  @override
  Future<List<TrainerProfile>> listTrainers({required int gymId}) async =>
      trainers;

  @override
  Future<TrainerProfile> createTrainer({
    required int gymId,
    required String name,
    String? bio,
  }) async => TrainerProfile(
    id: 4,
    publicId: '01t4',
    gymId: gymId,
    name: name,
    bio: bio,
    isActive: true,
  );

  @override
  Future<TrainerProfile> updateTrainer({
    required int trainerId,
    required String name,
    String? bio,
    bool? isActive,
  }) async => trainers.first;

  @override
  Future<List<ScheduleTemplate>> listTemplates({
    required int gymId,
    bool? onlyActive,
  }) async => templates;

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
  }) async => templates.first;

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
  }) async => templates.first;

  @override
  Future<List<ClassSession>> listSessions({
    required int gymId,
    required String fromDate,
    required String toDate,
  }) async => sessions;

  @override
  Future<List<ClassSession>> generateSessions({
    required int gymId,
    required String fromDate,
    required String toDate,
  }) async {
    lastGenerated = (gymId: gymId, fromDate: fromDate, toDate: toDate);
    return sessions;
  }

  @override
  Future<ClassSession> cancelSession({required int sessionId}) async {
    lastCancelledSessionId = sessionId;
    return ClassSession(
      id: sessionId,
      publicId: '01s101',
      gymId: 10,
      templateId: 7,
      trainerId: 3,
      title: 'Йога',
      capacity: 15,
      bookedCount: 2,
      availableSeats: 13,
      startsAt: DateTime.utc(2026, 11, 18, 9, 0),
      endsAt: DateTime.utc(2026, 11, 18, 10, 0),
      status: ClassSessionStatus.cancelled,
    );
  }

  @override
  Future<List<ClassBooking>> listSessionBookings({
    required int sessionId,
  }) async => bookings;
}

Future<BusinessSessionController> _session(BusinessRole role) async {
  final prefs = AppPreferences(storage: InMemoryTokenStorage());
  final session = BusinessSessionController(preferences: prefs)..setRole(role);
  await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
  return session;
}

void main() {
  testWidgets(
    'TrainersScreen hides create/edit from admin and allows owner to manage trainers',
    (tester) async {
      final repo = _FakeScheduleRepo();

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrainersScreen(
                repository: repo,
                sessionController: await _session(BusinessRole.admin),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Иван Петров'), findsOneWidget);
      expect(find.text('Добавить тренера'), findsNothing);
      expect(find.text('Изменить'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrainersScreen(
                repository: repo,
                sessionController: await _session(BusinessRole.owner),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Добавить тренера'), findsOneWidget);
      expect(find.text('Изменить'), findsOneWidget);
    },
  );

  testWidgets(
    'ScheduleTab enforces 62-day generation limit, cancels session, and opens bookings',
    (tester) async {
      final repo = _FakeScheduleRepo();
      final adminSession = await _session(BusinessRole.admin);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScheduleTab(
                repository: repo,
                sessionController: adminSession,
                initialFromDate: '2026-11-18',
                initialToDate: '2026-11-25',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Generation > 62 days is blocked on client.
      await tester.tap(find.text('Сгенерировать'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), '2027-02-15');
      await tester.tap(find.widgetWithText(UcraftButton, 'Сгенерировать').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Период генерации не должен превышать 62 дня.'),
        findsOneWidget,
      );
      expect(repo.lastGenerated, isNull);

      await tester.enterText(find.byType(TextField).at(1), '2026-11-25');
      await tester.tap(find.widgetWithText(UcraftButton, 'Сгенерировать').last);
      await tester.pumpAndSettle();
      expect(repo.lastGenerated?.toDate, '2026-11-25');

      // 2. Open bookings.
      await tester.tap(find.text('Записавшиеся'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionBookingsScreen), findsOneWidget);
      expect(find.text('Клиент №42'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // 3. Cancel session with refund notice.
      await tester.tap(find.text('Отменить'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('автоматически вернутся списанные посещения'),
        findsOneWidget,
      );
      await tester.tap(find.text('Отменить занятие').last);
      await tester.pumpAndSettle();

      expect(repo.lastCancelledSessionId, 101);
      expect(find.text('Отменено'), findsOneWidget);
    },
  );

  testWidgets(
    'Trainer can view session bookings but cannot manage templates or cancel sessions',
    (tester) async {
      final repo = _FakeScheduleRepo();
      final trainerSession = await _session(BusinessRole.trainer);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScheduleTab(
                repository: repo,
                sessionController: trainerSession,
                initialFromDate: '2026-11-18',
                initialToDate: '2026-11-25',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Шаблоны'), findsNothing);
      expect(find.text('Сгенерировать'), findsNothing);
      expect(find.text('Отменить'), findsNothing);
      expect(find.text('Записавшиеся'), findsOneWidget);
    },
  );
}
