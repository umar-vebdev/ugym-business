import 'package:ugym_core/ugym_core.dart';

import '../domain/trainers_schedule_models.dart';

/// REST implementation of [TrainersScheduleRepository] backed by `/api/v1/business`.
final class RemoteTrainersScheduleRepository
    implements TrainersScheduleRepository {
  const RemoteTrainersScheduleRepository({required this.httpClient});

  final UgymHttpClient httpClient;

  @override
  Future<List<TrainerProfile>> listTrainers({required int gymId}) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/trainers',
        queryParameters: <String, Object?>{'gym_id': gymId},
      );
      return _unwrapList(response.data)
          .map(_parseTrainer)
          .whereType<TrainerProfile>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<TrainerProfile> createTrainer({
    required int gymId,
    required String name,
    String? bio,
  }) async {
    final trimmedBio = bio?.trim();
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/trainers',
        data: <String, Object?>{
          'gym_id': gymId,
          'name': name.trim(),
          if (trimmedBio != null && trimmedBio.isNotEmpty) 'bio': trimmedBio,
        },
      );
      final trainer = _parseTrainer(_unwrapMap(response.data));
      if (trainer == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Trainer payload is incomplete.',
        );
      }
      return trainer;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<TrainerProfile> updateTrainer({
    required int trainerId,
    required String name,
    String? bio,
    bool? isActive,
  }) async {
    final trimmedBio = bio?.trim();
    try {
      final response = await httpClient.dio.patch<Object?>(
        '/business/trainers/$trainerId',
        data: <String, Object?>{
          'name': name.trim(),
          'bio': trimmedBio == null || trimmedBio.isEmpty ? null : trimmedBio,
          'is_active': ?isActive,
        },
      );
      final trainer = _parseTrainer(_unwrapMap(response.data));
      if (trainer == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Updated trainer payload is incomplete.',
        );
      }
      return trainer;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<ScheduleTemplate>> listTemplates({
    required int gymId,
    bool? onlyActive,
  }) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/schedule/templates',
        queryParameters: <String, Object?>{
          'gym_id': gymId,
          'only_active': ?onlyActive,
        },
      );
      return _unwrapList(response.data)
          .map(_parseTemplate)
          .whereType<ScheduleTemplate>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

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
  }) async {
    final trimmedDescription = description?.trim();
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/schedule/templates',
        data: <String, Object?>{
          'gym_id': gymId,
          'trainer_id': trainerId,
          'title': title.trim(),
          if (trimmedDescription != null && trimmedDescription.isNotEmpty)
            'description': trimmedDescription,
          'weekday': weekday,
          'start_time_minute': startTimeMinute,
          'duration_minutes': durationMinutes,
          'capacity': capacity,
        },
      );
      final template = _parseTemplate(_unwrapMap(response.data));
      if (template == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Schedule template payload is incomplete.',
        );
      }
      return template;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

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
  }) async {
    final trimmedDescription = description?.trim();
    try {
      final response = await httpClient.dio.patch<Object?>(
        '/business/schedule/templates/$templateId',
        data: <String, Object?>{
          'trainer_id': trainerId,
          'title': title.trim(),
          'description':
              trimmedDescription == null || trimmedDescription.isEmpty
              ? null
              : trimmedDescription,
          'weekday': weekday,
          'start_time_minute': startTimeMinute,
          'duration_minutes': durationMinutes,
          'capacity': capacity,
          'is_active': ?isActive,
        },
      );
      final template = _parseTemplate(_unwrapMap(response.data));
      if (template == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Updated template payload is incomplete.',
        );
      }
      return template;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<ClassSession>> listSessions({
    required int gymId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/schedule/sessions',
        queryParameters: <String, Object?>{
          'gym_id': gymId,
          'from_date': fromDate,
          'to_date': toDate,
        },
      );
      return _unwrapList(response.data)
          .map(_parseSession)
          .whereType<ClassSession>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<ClassSession>> generateSessions({
    required int gymId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/schedule/sessions/generate',
        data: <String, Object?>{
          'gym_id': gymId,
          'from_date': fromDate,
          'to_date': toDate,
        },
      );
      return _unwrapList(response.data)
          .map(_parseSession)
          .whereType<ClassSession>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<ClassSession> cancelSession({required int sessionId}) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/schedule/sessions/$sessionId/cancel',
      );
      final session = _parseSession(_unwrapMap(response.data));
      if (session == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Cancelled session payload is incomplete.',
        );
      }
      return session;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<ClassBooking>> listSessionBookings({
    required int sessionId,
  }) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/schedule/sessions/$sessionId/bookings',
      );
      return _unwrapList(response.data)
          .map(_parseBooking)
          .whereType<ClassBooking>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  TrainerProfile? _parseTrainer(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final publicId = _asString(raw['public_id']) ?? '';
    final gymId = _toInt(raw['gym_id']);
    final name = _asString(raw['name']);
    if (id == null || gymId == null || name == null) {
      return null;
    }
    return TrainerProfile(
      id: id,
      publicId: publicId,
      gymId: gymId,
      userId: _toInt(raw['user_id']),
      name: name,
      bio: _asString(raw['bio']),
      isActive: raw['is_active'] == true,
    );
  }

  ScheduleTemplate? _parseTemplate(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final publicId = _asString(raw['public_id']) ?? '';
    final gymId = _toInt(raw['gym_id']);
    final trainerId = _toInt(raw['trainer_id']);
    final title = _asString(raw['title']);
    final weekday = _toInt(raw['weekday']);
    final startTimeMinute = _toInt(raw['start_time_minute']);
    final durationMinutes = _toInt(raw['duration_minutes']);
    final capacity = _toInt(raw['capacity']);
    if (id == null ||
        gymId == null ||
        trainerId == null ||
        title == null ||
        weekday == null ||
        startTimeMinute == null ||
        durationMinutes == null ||
        capacity == null) {
      return null;
    }
    return ScheduleTemplate(
      id: id,
      publicId: publicId,
      gymId: gymId,
      trainerId: trainerId,
      title: title,
      description: _asString(raw['description']),
      weekday: weekday,
      startTimeMinute: startTimeMinute,
      durationMinutes: durationMinutes,
      capacity: capacity,
      isActive: raw['is_active'] == true,
    );
  }

  ClassSession? _parseSession(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final publicId = _asString(raw['public_id']) ?? '';
    final gymId = _toInt(raw['gym_id']);
    final templateId = _toInt(raw['template_id']);
    final trainerId = _toInt(raw['trainer_id']);
    final title = _asString(raw['title']);
    final capacity = _toInt(raw['capacity']);
    final bookedCount = _toInt(raw['booked_count']);
    final availableSeats = _toInt(raw['available_seats']);
    final startsAt = _toDateTime(raw['starts_at']);
    final endsAt = _toDateTime(raw['ends_at']);
    if (id == null ||
        gymId == null ||
        templateId == null ||
        trainerId == null ||
        title == null ||
        capacity == null ||
        bookedCount == null ||
        availableSeats == null ||
        startsAt == null ||
        endsAt == null) {
      return null;
    }
    return ClassSession(
      id: id,
      publicId: publicId,
      gymId: gymId,
      templateId: templateId,
      trainerId: trainerId,
      title: title,
      capacity: capacity,
      bookedCount: bookedCount,
      availableSeats: availableSeats,
      startsAt: startsAt,
      endsAt: endsAt,
      status: ClassSessionStatus.fromApi(_asString(raw['status'])),
    );
  }

  ClassBooking? _parseBooking(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final publicId = _asString(raw['public_id']) ?? '';
    final companyId = _toInt(raw['company_id']);
    final gymId = _toInt(raw['gym_id']);
    final sessionId = _toInt(raw['session_id']);
    final clientId = _toInt(raw['client_id']);
    final bookedAt = _toDateTime(raw['booked_at']);
    if (id == null ||
        companyId == null ||
        gymId == null ||
        sessionId == null ||
        clientId == null ||
        bookedAt == null) {
      return null;
    }
    return ClassBooking(
      id: id,
      publicId: publicId,
      companyId: companyId,
      gymId: gymId,
      sessionId: sessionId,
      clientId: clientId,
      membershipId: _toInt(raw['membership_id']),
      status: ClassBookingStatus.fromApi(_asString(raw['status'])),
      bookedAt: bookedAt,
      cancelledAt: _toDateTime(raw['cancelled_at']),
    );
  }

  Map<Object?, Object?> _unwrapMap(Object? body) {
    if (body is Map<Object?, Object?>) {
      final inner = body['data'];
      if (inner is Map<Object?, Object?>) {
        return inner;
      }
      return body;
    }
    throw const UgymApiException(
      code: 'INVALID_RESPONSE',
      message: 'Unexpected response format.',
    );
  }

  List<Object?> _unwrapList(Object? body) {
    if (body is Map<Object?, Object?>) {
      final inner = body['data'];
      if (inner is List<Object?>) {
        return inner;
      }
    }
    if (body is List<Object?>) {
      return body;
    }
    throw const UgymApiException(
      code: 'INVALID_RESPONSE',
      message: 'Unexpected list response format.',
    );
  }

  int? _toInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return null;
  }

  String? _asString(Object? raw) => raw is String ? raw : null;

  DateTime? _toDateTime(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  UgymApiException _mapError(DioException error) {
    final existing = error.error;
    if (existing is UgymApiException) {
      return existing;
    }
    return UgymErrorMapper.fromDioException(error);
  }
}
