import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/features/auth/data/remote_auth_repository.dart';
import 'package:ugym_core/ugym_core.dart';

final class _CapturedRequest {
  _CapturedRequest(this.options, this.decodedBody);

  final RequestOptions options;
  final Map<String, Object?> decodedBody;
}

final class _FakeAuthAdapter implements HttpClientAdapter {
  _FakeAuthAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;
  final List<_CapturedRequest> requests = <_CapturedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final raw = options.data;
    final body = raw is Map<Object?, Object?>
        ? raw.map((k, v) => MapEntry(k.toString(), v))
        : <String, Object?>{};
    requests.add(_CapturedRequest(options, body));
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int statusCode, Map<String, Object?> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  late InMemoryTokenStorage storage;
  late UgymHttpClient httpClient;
  late RemoteAuthRepository repository;

  setUp(() {
    storage = InMemoryTokenStorage();
    httpClient = UgymHttpClient(
      baseUrl: 'https://api.ugym.tj/api/v1',
      tokenStorage: storage,
    );
    repository = RemoteAuthRepository(
      httpClient: httpClient,
      tokenStorage: storage,
    );
  });

  group('RemoteAuthRepository', () {
    test('logs in via email or phone and stores Sanctum token', () async {
      final adapter = _FakeAuthAdapter((_) async {
        return _json(200, <String, Object?>{
          'data': <String, Object?>{'token': 'sanctum-abc'},
        });
      });
      httpClient.dio.httpClientAdapter = adapter;

      final token = await repository.login(
        email: ' owner@gym.tj ',
        password: 'password123',
        device: 'tablet',
      );

      expect(token, 'sanctum-abc');
      expect(await storage.readToken(), 'sanctum-abc');

      final req = adapter.requests.single;
      expect(req.options.path, '/auth/login');
      expect(req.options.headers.containsKey('Authorization'), isFalse);
      expect(req.decodedBody, <String, Object?>{
        'email': 'owner@gym.tj',
        'password': 'password123',
        'device': 'tablet',
      });

      await repository.login(phone: '+992900001122', password: 'password123');
      expect(adapter.requests.last.decodedBody, <String, Object?>{
        'phone': '+992900001122',
        'password': 'password123',
        'device': 'mobile',
      });
    });

    test(
      'registers user, sends OTP, verifies email, and resets password',
      () async {
        final adapter = _FakeAuthAdapter((options) async {
          if (options.path == '/auth/register') {
            return _json(201, <String, Object?>{
              'data': <String, Object?>{'id': 42, 'message': 'Created'},
            });
          }
          if (options.path == '/auth/send-otp') {
            return _json(200, <String, Object?>{
              'data': <String, Object?>{'message': 'OTP sent to email'},
              'message': 'OTP sent to email',
            });
          }
          if (options.path == '/auth/verify-email') {
            return _json(200, <String, Object?>{
              'data': <String, Object?>{'message': 'Email verified'},
              'message': 'Email verified',
            });
          }
          return _json(200, <String, Object?>{
            'data': <String, Object?>{'message': 'Password reset successful'},
            'message': 'Password reset successful',
          });
        });
        httpClient.dio.httpClientAdapter = adapter;

        final userId = await repository.registerUser(
          email: 'staff@gym.tj',
          password: 'password123',
        );
        expect(userId, 42);

        expect(
          await repository.sendEmailOtp(email: 'staff@gym.tj'),
          'OTP sent to email',
        );
        expect(
          await repository.verifyEmailOtp(
            email: 'staff@gym.tj',
            code: '123456',
          ),
          'Email verified',
        );
        expect(
          await repository.resetPassword(
            email: 'staff@gym.tj',
            code: '123456',
            newPassword: 'newpassword123',
          ),
          'Password reset successful',
        );

        expect(adapter.requests.last.decodedBody, <String, Object?>{
          'email': 'staff@gym.tj',
          'code': '123456',
          'password': 'newpassword123',
        });
      },
    );

    test('fetches current user with email_verified_at status', () async {
      await storage.writeToken('tok-1');
      httpClient.dio.httpClientAdapter = _FakeAuthAdapter((_) async {
        return _json(200, <String, Object?>{
          'id': 7,
          'name': 'Umar',
          'email': 'umar@gym.tj',
          'email_verified_at': '2026-11-17T06:00:00Z',
          'phone': '+992900001122',
          'is_phone_verified': false,
          'is_platform_admin': false,
        });
      });

      final user = await repository.getCurrentUser();
      expect(user.id, 7);
      expect(user.name, 'Umar');
      expect(user.isEmailVerified, isTrue);
      expect(user.isPlatformAdmin, isFalse);
    });

    test('logout clears local token even when network fails', () async {
      await storage.writeToken('tok-logout');
      httpClient.dio.httpClientAdapter = _FakeAuthAdapter((_) async {
        throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/auth/logout'),
          reason: 'offline',
        );
      });

      await repository.logout();
      expect(await storage.readToken(), isNull);
    });

    test('maps 400, 401, 422, and 429 responses to UgymApiException', () async {
      final statusCodes = <int, String>{
        400: 'OTP_INVALID',
        401: 'INVALID_CREDENTIALS',
        422: 'VALIDATION_FAILED',
        429: 'TOO_MANY_REQUESTS',
      };

      for (final entry in statusCodes.entries) {
        httpClient.dio.httpClientAdapter = _FakeAuthAdapter((_) async {
          return _json(entry.key, <String, Object?>{
            'error': <String, Object?>{
              'code': entry.value,
              'message': 'Error ${entry.key}',
              if (entry.key == 422)
                'details': <String, Object?>{
                  'email': <String>['Invalid email'],
                },
            },
          });
        });

        await expectLater(
          () => repository.verifyEmailOtp(email: 'a@b.c', code: '000000'),
          throwsA(
            isA<UgymApiException>()
                .having((e) => e.statusCode, 'statusCode', entry.key)
                .having((e) => e.code, 'code', entry.value),
          ),
        );
      }
    });
  });
}
