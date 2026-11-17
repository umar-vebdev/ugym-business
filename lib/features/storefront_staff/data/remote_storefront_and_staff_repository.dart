import 'package:ugym_core/ugym_core.dart';

import '../domain/storefront_and_staff_models.dart';

/// REST implementation of [StorefrontAndStaffRepository] backed by `/api/v1/business`.
final class RemoteStorefrontAndStaffRepository
    implements StorefrontAndStaffRepository {
  const RemoteStorefrontAndStaffRepository({required this.httpClient});

  final UgymHttpClient httpClient;

  @override
  Future<GymProfile> updateGymProfile({
    required int gymId,
    required GymProfileInput input,
  }) async {
    try {
      final response = await httpClient.dio.put<Object?>(
        '/business/gyms/$gymId/profile',
        data: <String, Object?>{
          'description': ?_trimOrNull(input.description),
          'address': ?_trimOrNull(input.address),
          'district': ?_trimOrNull(input.district),
          'latitude': ?input.latitude,
          'longitude': ?input.longitude,
          'phone': ?_trimOrNull(input.phone),
          'working_hours': ?input.workingHours,
          'amenities': ?input.amenities,
        },
      );
      return _requireProfile(_unwrapMap(response.data), fallbackGymId: gymId);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<GymProfile> submitGymProfile({required int gymId}) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/gyms/$gymId/profile/submit',
      );
      return _requireProfile(_unwrapMap(response.data), fallbackGymId: gymId);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<GymProfile> setGymPublication({
    required int gymId,
    required bool isPublic,
  }) async {
    try {
      final response = await httpClient.dio.patch<Object?>(
        '/business/gyms/$gymId/publication',
        data: <String, Object?>{'is_public': isPublic},
      );
      return _requireProfile(_unwrapMap(response.data), fallbackGymId: gymId);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<GymPhoto> uploadGymPhoto({
    required int gymId,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap(<String, Object?>{
        'photo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await httpClient.dio.post<Object?>(
        '/business/gyms/$gymId/photos',
        data: formData,
      );
      final data = _unwrapMap(response.data);
      final id = _toInt(data['id']);
      final parsedGymId = _toInt(data['gym_id']) ?? gymId;
      final url = _asString(data['url']);
      final order = _toInt(data['order']) ?? 0;
      final createdAt = _toDateTime(data['created_at']);
      if (id == null || url == null || createdAt == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Uploaded photo payload is incomplete.',
        );
      }
      return GymPhoto(
        id: id,
        gymId: parsedGymId,
        url: url,
        order: order,
        createdAt: createdAt,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> deleteGymPhoto({
    required int gymId,
    required int photoId,
  }) async {
    try {
      await httpClient.dio.delete<Object?>(
        '/business/gyms/$gymId/photos/$photoId',
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<StaffMember>> listStaff() async {
    try {
      final response = await httpClient.dio.get<Object?>('/business/staff');
      return _unwrapList(response.data)
          .map(_parseStaffMember)
          .whereType<StaffMember>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StaffMember> inviteStaff({
    required String email,
    required StaffRoleValue role,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/staff',
        data: <String, Object?>{'email': email.trim(), 'role': role.apiValue},
      );
      final member = _parseStaffMember(_unwrapMap(response.data));
      if (member == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Invited staff payload is incomplete.',
        );
      }
      return member;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StaffMember> updateStaffRole({
    required int staffId,
    required StaffRoleValue role,
  }) async {
    try {
      final response = await httpClient.dio.patch<Object?>(
        '/business/staff/$staffId',
        data: <String, Object?>{'role': role.apiValue},
      );
      final member = _parseStaffMember(_unwrapMap(response.data));
      if (member == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Updated staff payload is incomplete.',
        );
      }
      return member;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> deleteStaff({required int staffId}) async {
    try {
      await httpClient.dio.delete<Object?>('/business/staff/$staffId');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  GymProfile _requireProfile(
    Map<Object?, Object?> data, {
    required int fallbackGymId,
  }) {
    final rawAmenities = data['amenities'];
    final amenities = rawAmenities is List<Object?>
        ? rawAmenities.whereType<String>().toList(growable: false)
        : const <String>[];

    return GymProfile(
      gymId: _toInt(data['gym_id']) ?? fallbackGymId,
      isPublic: data['is_public'] == true,
      moderationStatus: ModerationStatus.fromApi(
        _asString(data['moderation_status']),
      ),
      rejectionReason: _asString(data['rejection_reason']),
      description: _asString(data['description']),
      address: _asString(data['address']),
      district: _asString(data['district']),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      phone: _asString(data['phone']),
      workingHours: data['working_hours'],
      amenities: amenities,
    );
  }

  StaffMember? _parseStaffMember(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final userId = _toInt(raw['user_id']);
    final companyId = _toInt(raw['company_id']);
    if (id == null || userId == null || companyId == null) {
      return null;
    }
    return StaffMember(
      id: id,
      userId: userId,
      companyId: companyId,
      role: StaffRoleValue.fromApi(_asString(raw['role'])),
      name: _asString(raw['name']),
      phone: _asString(raw['phone']),
      email: _asString(raw['email']),
    );
  }

  String? _trimOrNull(String? raw) {
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
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

  double? _toDouble(Object? raw) {
    if (raw is double) {
      return raw;
    }
    if (raw is num) {
      return raw.toDouble();
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
