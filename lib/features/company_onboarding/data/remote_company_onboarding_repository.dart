import 'package:ugym_core/ugym_core.dart';

import '../domain/company_onboarding_models.dart';

/// REST implementation of [CompanyOnboardingRepository] backed by `/api/v1/business`.
final class RemoteCompanyOnboardingRepository
    implements CompanyOnboardingRepository {
  const RemoteCompanyOnboardingRepository({required this.httpClient});

  final UgymHttpClient httpClient;

  @override
  Future<CreatedCompanyResult> createCompany({
    required String companyName,
    required String gymName,
    String? gymAddress,
  }) async {
    final trimmedAddress = gymAddress?.trim();
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/companies',
        data: <String, Object?>{
          'company_name': companyName.trim(),
          'gym_name': gymName.trim(),
          if (trimmedAddress != null && trimmedAddress.isNotEmpty)
            'gym_address': trimmedAddress,
        },
      );

      final data = _unwrapMap(response.data);
      final companyId = _toInt(data['company_id']);
      final gymId = _toInt(data['gym_id']);
      if (companyId == null || gymId == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Company creation response is missing identifiers.',
        );
      }

      return CreatedCompanyResult(companyId: companyId, gymId: gymId);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<GymBranch>> listGyms() async {
    try {
      final response = await httpClient.dio.get<Object?>('/business/gyms');
      final list = _unwrapList(response.data);
      return list.map(_parseGym).whereType<GymBranch>().toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<GymBranch> createGym({
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  }) async {
    final trimmedAddress = address?.trim();
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/gyms',
        data: <String, Object?>{
          'name': name.trim(),
          if (trimmedAddress != null && trimmedAddress.isNotEmpty)
            'address': trimmedAddress,
          'timezone': timezone.trim(),
          'geo_check_enabled': geoCheckEnabled,
          'geo_check_radius_meters': geoCheckRadiusMeters,
        },
      );

      final gym = _parseGym(_unwrapMap(response.data));
      if (gym == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Gym payload is missing in server response.',
        );
      }
      return gym;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<GymBranch> updateGym({
    required int gymId,
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  }) async {
    final trimmedAddress = address?.trim();
    try {
      final response = await httpClient.dio.patch<Object?>(
        '/business/gyms/$gymId',
        data: <String, Object?>{
          'name': name.trim(),
          'address': trimmedAddress != null && trimmedAddress.isNotEmpty
              ? trimmedAddress
              : null,
          'timezone': timezone.trim(),
          'geo_check_enabled': geoCheckEnabled,
          'geo_check_radius_meters': geoCheckRadiusMeters,
        },
      );

      final gym = _parseGym(_unwrapMap(response.data));
      if (gym == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Gym payload is missing in server response.',
        );
      }
      return gym;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<CurrencyOption>> listCurrencies() async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/currencies',
      );
      final list = _unwrapList(response.data);
      return list
          .map(_parseCurrency)
          .whereType<CurrencyOption>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<String> updateCompanyCurrency({required int currencyId}) async {
    try {
      final response = await httpClient.dio.patch<Object?>(
        '/business/company/currency',
        data: <String, Object?>{'currency_id': currencyId},
      );
      final data = _unwrapMap(response.data);
      final code = data['currency_code'];
      if (code is! String || code.isEmpty) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Currency code is missing in server response.',
        );
      }
      return code;
    } on DioException catch (error) {
      throw _mapError(error);
    }
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

  GymBranch? _parseGym(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final companyId = _toInt(raw['company_id']);
    final name = raw['name'];
    if (id == null || companyId == null || name is! String || name.isEmpty) {
      return null;
    }

    final rawTimezone = raw['timezone'];
    final radius = _toInt(raw['geo_check_radius_meters']) ?? 200;

    return GymBranch(
      id: id,
      companyId: companyId,
      name: name,
      address: raw['address'] is String ? raw['address'] as String : null,
      timezone: rawTimezone is String && rawTimezone.isNotEmpty
          ? rawTimezone
          : 'Asia/Dushanbe',
      geoCheckEnabled: raw['geo_check_enabled'] == true,
      geoCheckRadiusMeters: radius,
    );
  }

  CurrencyOption? _parseCurrency(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final code = raw['code'];
    final name = raw['name'];
    if (id == null || code is! String || name is! String) {
      return null;
    }
    return CurrencyOption(
      id: id,
      code: code,
      name: name,
      symbol: raw['symbol'] is String ? raw['symbol'] as String : null,
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

  UgymApiException _mapError(DioException error) {
    final existing = error.error;
    if (existing is UgymApiException) {
      return existing;
    }
    return UgymErrorMapper.fromDioException(error);
  }
}
