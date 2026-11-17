import 'package:ugym_core/ugym_core.dart';

import '../domain/auth_repository.dart';
import '../domain/authenticated_user.dart';

/// REST implementation of [AuthRepository] backed by `/api/v1` endpoints.
final class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository({
    required this.httpClient,
    required this.tokenStorage,
  });

  final UgymHttpClient httpClient;
  final TokenStorage tokenStorage;

  static final Options _skipAuthOptions = Options(
    extra: const <String, Object?>{'skipAuth': true},
  );

  @override
  Future<String> login({
    String? email,
    String? phone,
    required String password,
    String device = 'mobile',
  }) async {
    final payload = <String, Object?>{
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'password': password,
      'device': device,
    };

    try {
      final response = await httpClient.dio.post<Object?>(
        '/auth/login',
        data: payload,
        options: _skipAuthOptions,
      );
      final data = _unwrapDataMap(response.data);
      final token = data['token'];
      if (token is! String || token.isEmpty) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Auth token is missing in server response.',
        );
      }
      await tokenStorage.writeToken(token);
      return token;
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  @override
  Future<int> registerUser({
    String? email,
    String? phone,
    required String password,
  }) async {
    final payload = <String, Object?>{
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'password': password,
    };

    try {
      final response = await httpClient.dio.post<Object?>(
        '/auth/register',
        data: payload,
        options: _skipAuthOptions,
      );
      final data = _unwrapDataMap(response.data);
      final rawId = data['id'];
      final int? userId = rawId is int
          ? rawId
          : (rawId is num ? rawId.toInt() : null);
      if (userId == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'User identifier is missing in server response.',
        );
      }
      return userId;
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  @override
  Future<String> sendEmailOtp({required String email}) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/auth/send-otp',
        data: <String, Object?>{'email': email.trim()},
        options: _skipAuthOptions,
      );
      return _extractMessage(
        response.data,
        fallback: 'Verification code sent.',
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  @override
  Future<String> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/auth/verify-email',
        data: <String, Object?>{'email': email.trim(), 'code': code.trim()},
        options: _skipAuthOptions,
      );
      return _extractMessage(response.data, fallback: 'Email verified.');
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/auth/reset-password',
        data: <String, Object?>{
          'email': email.trim(),
          'code': code.trim(),
          'password': newPassword,
        },
        options: _skipAuthOptions,
      );
      return _extractMessage(
        response.data,
        fallback: 'Password has been reset.',
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await httpClient.dio.post<Object?>('/auth/logout');
    } on Object {
      // Clear local session token regardless of network availability.
    } finally {
      await tokenStorage.deleteToken();
    }
  }

  @override
  Future<AuthenticatedUser> getCurrentUser() async {
    try {
      final response = await httpClient.dio.get<Object?>('/user');
      final rawBody = response.data;
      if (rawBody is! Map<Object?, Object?>) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'User payload is missing in server response.',
        );
      }

      final Map<Object?, Object?> map = rawBody['data'] is Map<Object?, Object?>
          ? rawBody['data'] as Map<Object?, Object?>
          : rawBody;

      final rawId = map['id'];
      final int? id = rawId is int
          ? rawId
          : (rawId is num ? rawId.toInt() : null);
      if (id == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'User identifier is missing in server response.',
        );
      }

      final rawVerifiedAt = map['email_verified_at'];
      final DateTime? emailVerifiedAt = rawVerifiedAt is String
          ? DateTime.tryParse(rawVerifiedAt)
          : null;

      return AuthenticatedUser(
        id: id,
        name: map['name'] is String ? map['name'] as String : null,
        email: map['email'] is String ? map['email'] as String : null,
        emailVerifiedAt: emailVerifiedAt,
        phone: map['phone'] is String ? map['phone'] as String : null,
        isPhoneVerified: map['is_phone_verified'] == true,
        isPlatformAdmin: map['is_platform_admin'] == true,
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Map<Object?, Object?> _unwrapDataMap(Object? body) {
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

  String _extractMessage(Object? body, {required String fallback}) {
    if (body is Map<Object?, Object?>) {
      final data = body['data'];
      if (data is Map<Object?, Object?>) {
        final innerMsg = data['message'];
        if (innerMsg is String && innerMsg.trim().isNotEmpty) {
          return innerMsg;
        }
      }
      final rootMsg = body['message'];
      if (rootMsg is String && rootMsg.trim().isNotEmpty) {
        return rootMsg;
      }
    }
    return fallback;
  }

  UgymApiException _mapDioError(DioException error) {
    final existing = error.error;
    if (existing is UgymApiException) {
      return existing;
    }
    return UgymErrorMapper.fromDioException(error);
  }
}
