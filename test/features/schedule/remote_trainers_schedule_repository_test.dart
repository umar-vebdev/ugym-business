import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/network/business_api_client.dart';
import 'package:ugym_business/features/schedule/data/remote_trainers_schedule_repository.dart';
import 'package:ugym_business/features/schedule/domain/trainers_schedule_models.dart';
import 'package:ugym_core/ugym_core.dart';

final class _MockScheduleAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  Object? lastData;
  int nextStatusCode = 200;
  Object? nextBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    lastData = options.data;
    return ResponseBody.fromString(
      jsonEncode(nextBody),
      nextStatusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  late _MockScheduleAdapter adapter;
  late RemoteTrainersScheduleRepository repository;

  setUp(() {
    adapter = _MockScheduleAdapter();
    final apiClient = BusinessApiClient(
      config: const AppConfig.dev(),
      tokenStorage: InMemoryTokenStorage(),
    );
    apiClient.httpClient.dio.httpClientAdapter = adapter;
    repository = RemoteTrainersScheduleRepository(
      httpClient: apiClient.httpClient,
    );
  });

  test('listTrainers, createTrainer, and updateTrainer work', () async {
    adapter.nextStatusCode = 200;
    adapter.nextBody = {
      'data': [
        {
          'id': 3,
          'public_id': '01jbt001',
          'gym_id': 10,
          'user_id': null,
          'name': 'Иван Петров',
          'bio': 'Кроссфит',
          'is_active': true,
        },
      ],
    };

    final trainers = await repository.listTrainers(gymId: 10);
    expect(adapter.lastRequest?.queryParameters, {'gym_id': 10});
    expect(trainers.single.name, 'Иван Петров');
    expect(trainers.single.isActive, isTrue);

    adapter.nextStatusCode = 201;
    adapter.nextBody = {
      'data': {
        'id': 4,
        'public_id': '01jbt002',
        'gym_id': 10,
        'user_id': null,
        'name': 'Алина',
        'bio': null,
        'is_active': true,
      },
    };
    final created = await repository.createTrainer(gymId: 10, name: ' Алина ');
    expect(created.id, 4);
    expect(adapter.lastData, {'gym_id': 10, 'name': 'Алина'});

    adapter.nextStatusCode = 200;
    adapter.nextBody = {
      'data': {
        'id': 4,
        'public_id': '01jbt002',
        'gym_id': 10,
        'user_id': null,
        'name': 'Алина',
        'bio': null,
        'is_active': false,
      },
    };
    final updated = await repository.updateTrainer(
      trainerId: 4,
      name: 'Алина',
      isActive: false,
    );
    expect(updated.isActive, isFalse);
  });

  test('templates list, create, and update format fields properly', () async {
    adapter.nextStatusCode = 200;
    adapter.nextBody = {
      'data': [
        {
          'id': 7,
          'public_id': '01tmpl7',
          'gym_id': 10,
          'trainer_id': 3,
          'title': 'Утренняя йога',
          'description': null,
          'weekday': 1,
          'start_time_minute': 540,
          'duration_minutes': 60,
          'capacity': 15,
          'is_active': true,
        },
      ],
    };

    final templates = await repository.listTemplates(
      gymId: 10,
      onlyActive: true,
    );
    expect(adapter.lastRequest?.queryParameters, {
      'gym_id': 10,
      'only_active': true,
    });
    expect(templates.single.formattedStartTime, '09:00');

    adapter.nextStatusCode = 201;
    adapter.nextBody = {
      'data': {
        'id': 8,
        'public_id': '01tmpl8',
        'gym_id': 10,
        'trainer_id': 3,
        'title': 'Бокс',
        'description': null,
        'weekday': 3,
        'start_time_minute': 1080,
        'duration_minutes': 90,
        'capacity': 20,
        'is_active': true,
      },
    };
    final created = await repository.createTemplate(
      gymId: 10,
      trainerId: 3,
      title: 'Бокс',
      weekday: 3,
      startTimeMinute: 1080,
      durationMinutes: 90,
      capacity: 20,
    );
    expect(created.id, 8);
    expect(created.formattedStartTime, '18:00');
  });

  test('sessions list, generate, cancel, and bookings work properly', () async {
    adapter.nextStatusCode = 200;
    adapter.nextBody = {
      'data': [
        {
          'id': 101,
          'public_id': '01sess101',
          'gym_id': 10,
          'template_id': 7,
          'trainer_id': 3,
          'title': 'Утренняя йога',
          'capacity': 15,
          'booked_count': 4,
          'available_seats': 11,
          'starts_at': '2026-11-18T09:00:00Z',
          'ends_at': '2026-11-18T10:00:00Z',
          'status': 'scheduled',
        },
      ],
    };

    final generated = await repository.generateSessions(
      gymId: 10,
      fromDate: '2026-11-18',
      toDate: '2026-11-25',
    );
    expect(adapter.lastRequest?.path, '/business/schedule/sessions/generate');
    expect(generated.single.bookedCount, 4);

    adapter.nextBody = {
      'data': {
        'id': 101,
        'public_id': '01sess101',
        'gym_id': 10,
        'template_id': 7,
        'trainer_id': 3,
        'title': 'Утренняя йога',
        'capacity': 15,
        'booked_count': 4,
        'available_seats': 11,
        'starts_at': '2026-11-18T09:00:00Z',
        'ends_at': '2026-11-18T10:00:00Z',
        'status': 'cancelled',
      },
    };
    final cancelled = await repository.cancelSession(sessionId: 101);
    expect(cancelled.status, ClassSessionStatus.cancelled);

    adapter.nextBody = {
      'data': [
        {
          'id': 500,
          'public_id': '01bk500',
          'company_id': 1,
          'gym_id': 10,
          'session_id': 101,
          'client_id': 42,
          'membership_id': 77,
          'status': 'booked',
          'booked_at': '2026-11-17T10:00:00Z',
          'cancelled_at': null,
        },
      ],
    };
    final bookings = await repository.listSessionBookings(sessionId: 101);
    expect(bookings.single.clientId, 42);
    expect(bookings.single.status, ClassBookingStatus.booked);
  });
}
