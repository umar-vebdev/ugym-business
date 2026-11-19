import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/main.dart';
import 'package:ugym_core/ugym_core.dart';

final class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
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

final class _NoOpVisitsRepo implements ReceptionVisitsRepository {
  @override
  Future<List<VisitRecord>> listCompanyVisits() async => const <VisitRecord>[];

  @override
  Future<List<VisitRecord>> listClientVisits({required int clientId}) async =>
      const <VisitRecord>[];

  @override
  Future<VisitRecord> cancelVisit({
    required int visitId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<GymQrToken> fetchGymQr({required int gymId}) =>
      throw UnimplementedError();

  @override
  Future<CheckInResult> registerManualVisit({
    required int clientId,
    required int gymId,
    DateTime? visitedAt,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  group('AppConfig.resolve and fromEnvironment', () {
    test('resolves dev, staging, prod, custom URL, and kiosk flag', () {
      final dev = AppConfig.resolve();
      expect(dev.flavor, AppFlavor.dev);
      expect(dev.apiBaseUrl, 'http://10.0.2.2:8000/api/v1');
      expect(dev.enableKioskMode, isTrue);

      final staging = AppConfig.resolve(flavorName: ' STAGING ');
      expect(staging.flavor, AppFlavor.staging);
      expect(staging.apiBaseUrl, 'https://staging-api.ugym.tj/api/v1');

      final prod = AppConfig.resolve(
        flavorName: 'production',
        apiBaseUrlOverride: 'https://custom.ugym.tj/api/v1',
        enableKioskMode: false,
      );
      expect(prod.flavor, AppFlavor.prod);
      expect(prod.apiBaseUrl, 'https://custom.ugym.tj/api/v1');
      expect(prod.enableKioskMode, isFalse);

      final envDefault = AppConfig.fromEnvironment();
      expect(envDefault.flavor, AppFlavor.dev);
      expect(envDefault.enableKioskMode, isTrue);
    });
  });

  group('Automatic trainer role detection on bootstrapFromApi', () {
    test('detects trainer when bookings probe returns 404 NOT_FOUND', () async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      await prefs.writeSelectedGymId(9);
      final session = BusinessSessionController(preferences: prefs);
      addTearDown(session.dispose);

      final client = UgymHttpClient(
        baseUrl: 'https://api.ugym.tj/api/v1',
        tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
      );
      client.dio.httpClientAdapter = _MockAdapter((options) async {
        if (options.path == '/business/schedule/sessions/1/bookings') {
          return _json(404, <String, Object?>{
            'error': <String, Object?>{
              'code': 'NOT_FOUND',
              'message': 'Session not found',
            },
          });
        }
        return _json(403, <String, Object?>{
          'error': <String, Object?>{
            'code': 'FORBIDDEN',
            'message': 'Forbidden',
          },
        });
      });

      final role = await session.bootstrapFromApi(client);
      expect(role, BusinessRole.trainer);
      expect(session.isReadOnly, isFalse);
      expect(session.selectedGym?.id, 9);
    });

    test('detects trainer when bookings probe returns 200', () async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(preferences: prefs);
      addTearDown(session.dispose);

      final client = UgymHttpClient(
        baseUrl: 'https://api.ugym.tj/api/v1',
        tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
      );
      client.dio.httpClientAdapter = _MockAdapter((options) async {
        if (options.path == '/business/schedule/sessions/1/bookings') {
          return _json(200, <String, Object?>{'data': <Object?>[]});
        }
        return _json(403, <String, Object?>{
          'error': <String, Object?>{
            'code': 'FORBIDDEN',
            'message': 'Forbidden',
          },
        });
      });

      final role = await session.bootstrapFromApi(client);
      expect(role, BusinessRole.trainer);
    });

    test(
      'detects trainer and enables read-only on 403 SUBSCRIPTION_EXPIRED probe',
      () async {
        final prefs = AppPreferences(storage: InMemoryTokenStorage());
        final session = BusinessSessionController(preferences: prefs);
        addTearDown(session.dispose);

        final client = UgymHttpClient(
          baseUrl: 'https://api.ugym.tj/api/v1',
          tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
        );
        client.dio.httpClientAdapter = _MockAdapter((options) async {
          if (options.path == '/business/schedule/sessions/1/bookings') {
            return _json(403, <String, Object?>{
              'error': <String, Object?>{
                'code': 'SUBSCRIPTION_EXPIRED',
                'message': 'Subscription expired',
              },
            });
          }
          return _json(403, <String, Object?>{
            'error': <String, Object?>{
              'code': 'FORBIDDEN',
              'message': 'Forbidden',
            },
          });
        });

        final role = await session.bootstrapFromApi(client);
        expect(role, BusinessRole.trainer);
        expect(session.isReadOnly, isTrue);
      },
    );
  });

  testWidgets(
    'BusinessShell hides kiosk button when enableKioskMode is false',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
      );
      await session.setGyms(const [GymSummary(id: 1, name: 'Центр')]);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        UgymBusinessApp(
          config: AppConfig.resolve(flavorName: 'prod', enableKioskMode: false),
          sessionController: session,
          visitsRepository: _NoOpVisitsRepo(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Операции'));
      await tester.pumpAndSettle();

      expect(find.text('Сканер QR клиента'), findsOneWidget);
      expect(find.text('Киоск QR зала'), findsNothing);
    },
  );
}
