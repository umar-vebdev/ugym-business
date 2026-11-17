import 'package:ugym_core/ugym_core.dart';

import '../domain/memberships_models.dart';

/// REST implementation of [MembershipsRepository] backed by `/api/v1/business`.
final class RemoteMembershipsRepository implements MembershipsRepository {
  const RemoteMembershipsRepository({required this.httpClient});

  final UgymHttpClient httpClient;

  @override
  Future<List<MembershipType>> listMembershipTypes({bool? onlyActive}) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/membership-types',
        queryParameters: <String, Object?>{'only_active': ?onlyActive},
      );
      return _unwrapList(response.data)
          .map(_parseMembershipType)
          .whereType<MembershipType>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<int> createMembershipType(CreateMembershipTypeInput input) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/membership-types',
        data: <String, Object?>{
          'name': input.name.trim(),
          'price_minor': input.priceMinor,
          if (input.currency != null && input.currency!.trim().isNotEmpty)
            'currency': input.currency!.trim().toUpperCase(),
          'kind': input.kind.apiValue,
          'start_mode': input.startMode.apiValue,
          if (input.visitsCount != null) 'visits_count': input.visitsCount,
          if (input.durationDays != null) 'duration_days': input.durationDays,
          if (input.validityDays != null) 'validity_days': input.validityDays,
          if (input.dailyLimit != null) 'daily_limit': input.dailyLimit,
          if (input.timeFrom != null) 'time_from': input.timeFrom,
          if (input.timeTo != null) 'time_to': input.timeTo,
          if (input.freezeMaxDays != null)
            'freeze_max_days': input.freezeMaxDays,
          if (input.freezeMaxTimes != null)
            'freeze_max_times': input.freezeMaxTimes,
        },
      );
      final data = _unwrapMap(response.data);
      final id = _toInt(data['id']);
      if (id == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Created membership type ID is missing.',
        );
      }
      return id;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<bool> setMembershipTypeActive({
    required int typeId,
    required bool isActive,
  }) async {
    try {
      final response = await httpClient.dio.patch<Object?>(
        '/business/membership-types/$typeId/active',
        data: <String, Object?>{'is_active': isActive},
      );
      final data = _unwrapMap(response.data);
      return data['updated'] == true;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<ClientMembership>> listClientMemberships({
    required int clientId,
  }) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/clients/$clientId/memberships',
      );
      return _unwrapList(response.data)
          .map(_parseClientMembership)
          .whereType<ClientMembership>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<ClientMembership>> listExpiringMemberships() async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/memberships/expiring',
      );
      return _unwrapList(response.data)
          .map(_parseClientMembership)
          .whereType<ClientMembership>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<MembershipFreezeState> freezeMembership({
    required int membershipId,
  }) async {
    return _postFreezeAction('/business/memberships/$membershipId/freeze');
  }

  @override
  Future<MembershipFreezeState> unfreezeMembership({
    required int membershipId,
  }) async {
    return _postFreezeAction('/business/memberships/$membershipId/unfreeze');
  }

  Future<MembershipFreezeState> _postFreezeAction(String path) async {
    try {
      final response = await httpClient.dio.post<Object?>(path);
      final data = _unwrapMap(response.data);
      final id = _toInt(data['id']);
      if (id == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Freeze state payload is incomplete.',
        );
      }
      return MembershipFreezeState(
        id: id,
        status: MembershipStatus.fromApi(_asString(data['status'])),
        freezeDaysUsed: _toInt(data['freeze_days_used']) ?? 0,
        freezeTimesUsed: _toInt(data['freeze_times_used']) ?? 0,
        frozenAt: _toDateTime(data['frozen_at']),
        endsAt: _toDateTime(data['ends_at']),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<ClientMembership> cancelMembership({
    required int membershipId,
    required String reason,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/memberships/$membershipId/cancel',
        data: <String, Object?>{'reason': reason.trim()},
      );
      final data = _unwrapMap(response.data);
      final id = _toInt(data['id']) ?? membershipId;
      return ClientMembership(
        id: id,
        clientId: _toInt(data['client_id']) ?? 0,
        typeId: _toInt(data['type_id']) ?? 0,
        kind: MembershipKind.fromApi(_asString(data['kind'])),
        status: MembershipStatus.fromApi(
          _asString(data['status']) ?? 'cancelled',
        ),
        cancellationReason: _asString(data['cancellation_reason']),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  MembershipType? _parseMembershipType(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final name = _asString(raw['name']);
    final priceMinor = _toInt(raw['price_minor']);
    final currency = _asString(raw['currency']);
    if (id == null || name == null || priceMinor == null || currency == null) {
      return null;
    }
    return MembershipType(
      id: id,
      name: name,
      kind: MembershipKind.fromApi(_asString(raw['kind'])),
      startMode: MembershipStartMode.fromApi(_asString(raw['start_mode'])),
      priceMinor: priceMinor,
      currency: currency,
      dailyLimit: _toInt(raw['daily_limit']) ?? 1,
      isActive: raw['is_active'] == true,
      visitsCount: _toInt(raw['visits_count']),
      durationDays: _toInt(raw['duration_days']),
      validityDays: _toInt(raw['validity_days']),
      timeFromMinute: _toInt(raw['time_from_minute']),
      timeToMinute: _toInt(raw['time_to_minute']),
      freezeMaxDays: _toInt(raw['freeze_max_days']) ?? 0,
      freezeMaxTimes: _toInt(raw['freeze_max_times']) ?? 0,
    );
  }

  ClientMembership? _parseClientMembership(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final clientId = _toInt(raw['client_id']);
    final typeId = _toInt(raw['type_id']);
    if (id == null || clientId == null || typeId == null) {
      return null;
    }
    return ClientMembership(
      id: id,
      clientId: clientId,
      typeId: typeId,
      kind: MembershipKind.fromApi(_asString(raw['kind'])),
      status: MembershipStatus.fromApi(_asString(raw['status'])),
      remainingVisits: _toInt(raw['remaining_visits']),
      startsAt: _toDateTime(raw['starts_at']),
      endsAt: _toDateTime(raw['ends_at']),
      freezeDaysUsed: _toInt(raw['freeze_days_used']) ?? 0,
      freezeTimesUsed: _toInt(raw['freeze_times_used']) ?? 0,
      frozenAt: _toDateTime(raw['frozen_at']),
      cancellationReason: _asString(raw['cancellation_reason']),
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
