import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/features/reception_qr/data/remote_reception_visits_repository.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_core/ugym_core.dart';

final class _CapturedVisitRequest {
  _CapturedVisitRequest(this.options, this.decodedBody);

  final RequestOptions options;
  final Map<String, Object?> decodedBody;
}

final class _FakeVisitsAdapter implements HttpClientAdapter {
  _FakeVisitsAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;
  final List<_CapturedVisitRequest> requests = <_CapturedVisitRequest>[];

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
    requests.add(_CapturedVisitRequest(options, body));
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
  late UgymHttpClient httpClient;
  late RemoteReceptionVisitsRepository repository;

  setUp(() {
    httpClient = UgymHttpClient(
      baseUrl: 'https://api.ugym.tj/api/v1',
      tokenStorage: InMemoryTokenStorage(initialToken: 'tok-staff'),
    );
    repository = RemoteReceptionVisitsRepository(httpClient: httpClient);
  });

  group('RemoteReceptionVisitsRepository', () {
    test('fetches dynamic 60s gym QR payload', () async {
      httpClient.dio.httpClientAdapter = _FakeVisitsAdapter((options) async {
        expect(options.path, '/business/gyms/5/qr');
        return _json(200, <String, Object?>{
          'data': <String, Object?>{
            'gym_id': 5,
            'gym_name': 'Center Gym',
            'slot': 29918400,
            'token': '5|29918400|hmacsig',
            'ttl_seconds': 60,
            'expires_at': '2026-11-17T07:10:00Z',
          },
        });
      });

      final qr = await repository.fetchGymQr(gymId: 5);
      expect(qr.gymId, 5);
      expect(qr.gymName, 'Center Gym');
      expect(qr.ttlSeconds, 60);
      expect(qr.token, '5|29918400|hmacsig');
    });

    test(
      'scans client QR with Idempotency-Key and maps 422 refusals',
      () async {
        final adapter = _FakeVisitsAdapter((options) async {
          return _json(201, <String, Object?>{
            'data': <String, Object?>{
              'id': 101,
              'company_id': 2,
              'gym_id': 5,
              'client_id': 88,
              'membership_id': 33,
              'method': 'client_qr',
              'status': 'completed',
              'visited_at': '2026-11-17T07:05:00Z',
              'visit_date': '2026-11-17',
              'remaining_visits': 7,
            },
          });
        });
        httpClient.dio.httpClientAdapter = adapter;

        const retryKey = '11111111-1111-4111-8111-111111111111';
        final result = await repository.checkInByClientQr(
          gymId: 5,
          token: 'client-qr-payload',
          device: 'iPad Reception',
          idempotencyKey: retryKey,
        );

        expect(result.method, VisitMethod.clientQr);
        expect(result.remainingVisits, 7);
        expect(
          adapter.requests.single.options.headers['Idempotency-Key'],
          retryKey,
        );

        // Verify 422 check-in rule refusal mapping.
        for (final code in const [
          'NO_ACTIVE_MEMBERSHIP',
          'MEMBERSHIP_FROZEN',
          'DAILY_LIMIT_EXCEEDED',
          'OUTSIDE_ALLOWED_TIME',
          'INVALID_QR_TOKEN',
        ]) {
          httpClient.dio.httpClientAdapter = _FakeVisitsAdapter((_) async {
            return _json(422, <String, Object?>{
              'error': <String, Object?>{
                'code': code,
                'message': 'Refused: $code',
              },
            });
          });

          await expectLater(
            () => repository.checkInByClientQr(gymId: 5, token: 'bad'),
            throwsA(
              isA<UgymApiException>()
                  .having((e) => e.statusCode, 'statusCode', 422)
                  .having((e) => e.code, 'code', code),
            ),
          );
        }
      },
    );

    test(
      'registers backdated manual visit, lists visits, and cancels within 24h',
      () async {
        final adapter = _FakeVisitsAdapter((options) async {
          if (options.path == '/business/clients/88/visits' &&
              options.method == 'POST') {
            return _json(201, <String, Object?>{
              'data': <String, Object?>{
                'id': 102,
                'company_id': 2,
                'gym_id': 5,
                'client_id': 88,
                'membership_id': 33,
                'method': 'manual',
                'status': 'completed',
                'visited_at': '2026-11-16T10:00:00Z',
                'visit_date': '2026-11-16',
                'remaining_visits': null,
              },
            });
          }
          if (options.path == '/business/visits/102/cancel') {
            return _json(200, <String, Object?>{
              'data': <String, Object?>{
                'id': 102,
                'company_id': 2,
                'gym_id': 5,
                'client_id': 88,
                'membership_id': 33,
                'method': 'manual',
                'status': 'cancelled',
                'visited_at': '2026-11-16T10:00:00Z',
                'visit_date': '2026-11-16',
                'cancel_reason': 'Mistaken check-in',
                'cancelled_by_user_id': 1,
                'cancelled_at': '2026-11-17T07:00:00Z',
              },
            });
          }
          return _json(200, <String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'id': 102,
                'company_id': 2,
                'gym_id': 5,
                'client_id': 88,
                'membership_id': 33,
                'method': 'manual',
                'status': 'completed',
                'visited_at': '2026-11-16T10:00:00Z',
                'visit_date': '2026-11-16',
              },
            ],
          });
        });
        httpClient.dio.httpClientAdapter = adapter;

        final backdated = DateTime.utc(2026, 11, 16, 10, 0);
        final manual = await repository.registerManualVisit(
          clientId: 88,
          gymId: 5,
          visitedAt: backdated,
        );
        expect(manual.method, VisitMethod.manual);
        expect(
          adapter.requests.first.options.headers['Idempotency-Key'],
          isA<String>(),
        );
        expect(
          adapter.requests.first.decodedBody['visited_at'],
          '2026-11-16T10:00:00.000Z',
        );

        final companyVisits = await repository.listCompanyVisits();
        final clientVisits = await repository.listClientVisits(clientId: 88);
        expect(companyVisits, hasLength(1));
        expect(
          clientVisits.single.canCancelAt(DateTime.utc(2026, 11, 17, 9)),
          isTrue,
        );
        expect(
          clientVisits.single.canCancelAt(DateTime.utc(2026, 11, 17, 11)),
          isFalse,
        );

        final cancelled = await repository.cancelVisit(
          visitId: 102,
          reason: 'Mistaken check-in',
        );
        expect(cancelled.status, VisitStatus.cancelled);
        expect(cancelled.cancelReason, 'Mistaken check-in');
        expect(cancelled.canCancelAt(DateTime.utc(2026, 11, 17, 9)), isFalse);
      },
    );
  });
}
