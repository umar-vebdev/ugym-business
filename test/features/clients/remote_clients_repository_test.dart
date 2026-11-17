import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/network/business_api_client.dart';
import 'package:ugym_business/features/clients/data/remote_clients_repository.dart';
import 'package:ugym_business/features/clients/domain/clients_models.dart';
import 'package:ugym_core/ugym_core.dart';

final class _MockClientsAdapter implements HttpClientAdapter {
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
  late _MockClientsAdapter adapter;
  late RemoteClientsRepository repository;

  setUp(() {
    adapter = _MockClientsAdapter();
    final apiClient = BusinessApiClient(
      config: const AppConfig.dev(),
      tokenStorage: InMemoryTokenStorage(),
    );
    apiClient.httpClient.dio.httpClientAdapter = adapter;
    repository = RemoteClientsRepository(httpClient: apiClient.httpClient);
  });

  test(
    'listClients sends search/pagination params and parses ClientsPage',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': [
          {
            'id': 11,
            'name': 'Фарход',
            'phone': '+992900001122',
            'email': 'farhod@gym.tj',
            'linked': true,
          },
          {
            'id': 12,
            'name': 'Зарина',
            'phone': '+992900003344',
            'email': null,
            'linked': false,
          },
        ],
        'meta': {'page': 1, 'per_page': 20, 'total': 25},
      };

      final page = await repository.listClients(search: ' Фар ', page: 1);

      expect(adapter.lastRequest?.path, '/business/clients');
      expect(adapter.lastRequest?.queryParameters, {
        'search': 'Фар',
        'page': 1,
        'per_page': 20,
      });
      expect(page.page, 1);
      expect(page.perPage, 20);
      expect(page.total, 25);
      expect(page.hasMore, isTrue);
      expect(page.items, const [
        ClientSummary(
          id: 11,
          name: 'Фарход',
          phone: '+992900001122',
          email: 'farhod@gym.tj',
          linked: true,
        ),
        ClientSummary(
          id: 12,
          name: 'Зарина',
          phone: '+992900003344',
          linked: false,
        ),
      ]);
    },
  );

  test('createClient sends trimmed payload and returns created id', () async {
    adapter.nextStatusCode = 201;
    adapter.nextBody = {
      'data': {'id': 42},
    };

    final id = await repository.createClient(
      name: ' Рустам ',
      phone: '+992901112233',
      email: 'rustam@gym.tj',
    );

    expect(adapter.lastRequest?.path, '/business/clients');
    expect(adapter.lastData, {
      'name': 'Рустам',
      'phone': '+992901112233',
      'email': 'rustam@gym.tj',
    });
    expect(id, 42);
  });

  test(
    'createClient maps 409 CLIENT_PHONE_EXISTS to UgymApiException',
    () async {
      adapter.nextStatusCode = 409;
      adapter.nextBody = {
        'error': {
          'code': 'CLIENT_PHONE_EXISTS',
          'message': 'Клиент с таким телефоном уже существует.',
        },
      };

      expect(
        () => repository.createClient(name: 'Рустам', phone: '+992901112233'),
        throwsA(
          isA<UgymApiException>().having(
            (e) => e.code,
            'code',
            'CLIENT_PHONE_EXISTS',
          ),
        ),
      );
    },
  );

  test(
    'mergeClients sends source_id and target_id and returns merged flag',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': {'merged': true},
      };

      final merged = await repository.mergeClients(sourceId: 12, targetId: 11);

      expect(adapter.lastRequest?.path, '/business/clients/merge');
      expect(adapter.lastData, {'source_id': 12, 'target_id': 11});
      expect(merged, isTrue);
    },
  );
}
