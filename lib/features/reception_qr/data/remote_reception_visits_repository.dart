import 'package:ugym_core/ugym_core.dart';

import '../domain/reception_visits_models.dart';

/// REST implementation of [ReceptionVisitsRepository] backed by `/api/v1/business`.
final class RemoteReceptionVisitsRepository
    implements ReceptionVisitsRepository {
  const RemoteReceptionVisitsRepository({required this.httpClient});

  final UgymHttpClient httpClient;

  @override
  Future<GymQrToken> fetchGymQr({required int gymId}) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/gyms/$gymId/qr',
      );
      final data = _unwrapMap(response.data);
      final parsedGymId = _toInt(data['gym_id']);
      final gymName = data['gym_name'];
      final slot = _toInt(data['slot']);
      final token = data['token'];
      final ttlSeconds = _toInt(data['ttl_seconds']) ?? 60;
      final expiresAt = _toDateTime(data['expires_at']);

      if (parsedGymId == null ||
          gymName is! String ||
          slot == null ||
          token is! String ||
          token.isEmpty ||
          expiresAt == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Gym QR payload is incomplete.',
        );
      }

      return GymQrToken(
        gymId: parsedGymId,
        gymName: gymName,
        slot: slot,
        token: token,
        ttlSeconds: ttlSeconds,
        expiresAt: expiresAt,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  }) async {
    final trimmedDevice = device?.trim();
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/gyms/$gymId/check-in-qr',
        data: <String, Object?>{
          'token': token.trim(),
          if (trimmedDevice != null && trimmedDevice.isNotEmpty)
            'device': trimmedDevice,
        },
        options: UgymHttpClient.idempotentOptions(
          idempotencyKey: idempotencyKey,
        ),
      );
      return _parseCheckInResult(_unwrapMap(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<VisitRecord>> listCompanyVisits() async {
    try {
      final response = await httpClient.dio.get<Object?>('/business/visits');
      return _unwrapList(response.data)
          .map(_parseVisitRecord)
          .whereType<VisitRecord>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<VisitRecord>> listClientVisits({required int clientId}) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/clients/$clientId/visits',
      );
      return _unwrapList(response.data)
          .map(_parseVisitRecord)
          .whereType<VisitRecord>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CheckInResult> registerManualVisit({
    required int clientId,
    required int gymId,
    DateTime? visitedAt,
    String? device,
    String? idempotencyKey,
  }) async {
    final trimmedDevice = device?.trim();
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/clients/$clientId/visits',
        data: <String, Object?>{
          'gym_id': gymId,
          if (visitedAt != null)
            'visited_at': visitedAt.toUtc().toIso8601String(),
          if (trimmedDevice != null && trimmedDevice.isNotEmpty)
            'device': trimmedDevice,
        },
        options: UgymHttpClient.idempotentOptions(
          idempotencyKey: idempotencyKey,
        ),
      );
      return _parseCheckInResult(_unwrapMap(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<VisitRecord> cancelVisit({
    required int visitId,
    required String reason,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/visits/$visitId/cancel',
        data: <String, Object?>{'reason': reason.trim()},
      );
      final parsed = _parseVisitRecord(_unwrapMap(response.data));
      if (parsed == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Visit payload is missing in server response.',
        );
      }
      return parsed;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  CheckInResult _parseCheckInResult(Map<Object?, Object?> map) {
    final id = _toInt(map['id']);
    final companyId = _toInt(map['company_id']);
    final gymId = _toInt(map['gym_id']);
    final clientId = _toInt(map['client_id']);
    final membershipId = _toInt(map['membership_id']);
    final visitedAt = _toDateTime(map['visited_at']);
    final visitDate = map['visit_date'];

    if (id == null ||
        companyId == null ||
        gymId == null ||
        clientId == null ||
        membershipId == null ||
        visitedAt == null ||
        visitDate is! String) {
      throw const UgymApiException(
        code: 'INVALID_RESPONSE',
        message: 'Check-in result payload is incomplete.',
      );
    }

    return CheckInResult(
      id: id,
      companyId: companyId,
      gymId: gymId,
      clientId: clientId,
      membershipId: membershipId,
      method: VisitMethod.fromApi(map['method'] as String?),
      status: VisitStatus.fromApi(map['status'] as String?),
      visitedAt: visitedAt,
      visitDate: visitDate,
      remainingVisits: _toInt(map['remaining_visits']),
    );
  }

  VisitRecord? _parseVisitRecord(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }

    final id = _toInt(raw['id']);
    final companyId = _toInt(raw['company_id']);
    final gymId = _toInt(raw['gym_id']);
    final clientId = _toInt(raw['client_id']);
    final membershipId = _toInt(raw['membership_id']);
    final visitedAt = _toDateTime(raw['visited_at']);
    final visitDate = raw['visit_date'];

    if (id == null ||
        companyId == null ||
        gymId == null ||
        clientId == null ||
        membershipId == null ||
        visitedAt == null ||
        visitDate is! String) {
      return null;
    }

    return VisitRecord(
      id: id,
      companyId: companyId,
      gymId: gymId,
      clientId: clientId,
      membershipId: membershipId,
      method: VisitMethod.fromApi(
        raw['method'] is String ? raw['method'] as String : null,
      ),
      status: VisitStatus.fromApi(
        raw['status'] is String ? raw['status'] as String : null,
      ),
      visitedAt: visitedAt,
      visitDate: visitDate,
      registeredByUserId: _toInt(raw['registered_by_user_id']),
      cancelReason: raw['cancel_reason'] is String
          ? raw['cancel_reason'] as String
          : null,
      cancelledByUserId: _toInt(raw['cancelled_by_user_id']),
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
