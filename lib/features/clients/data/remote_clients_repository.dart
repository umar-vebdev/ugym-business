import 'package:ugym_core/ugym_core.dart';

import '../domain/clients_models.dart';

/// REST implementation of [ClientsRepository] backed by `/api/v1/business`.
final class RemoteClientsRepository implements ClientsRepository {
  const RemoteClientsRepository({required this.httpClient});

  final UgymHttpClient httpClient;

  @override
  Future<ClientsPage> listClients({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final trimmedSearch = search?.trim();
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/clients',
        queryParameters: <String, Object?>{
          if (trimmedSearch != null && trimmedSearch.isNotEmpty)
            'search': trimmedSearch,
          'page': page,
          'per_page': perPage,
        },
      );
      return _parseClientsPage(
        response.data,
        fallbackPage: page,
        fallbackPerPage: perPage,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<int> createClient({
    required String name,
    required String phone,
    String? email,
  }) async {
    final trimmedEmail = email?.trim();
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/clients',
        data: <String, Object?>{
          'name': name.trim(),
          'phone': phone.trim(),
          if (trimmedEmail != null && trimmedEmail.isNotEmpty)
            'email': trimmedEmail,
        },
      );
      final data = _unwrapMap(response.data);
      final id = _toInt(data['id']);
      if (id == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Created client ID is missing.',
        );
      }
      return id;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<bool> mergeClients({
    required int sourceId,
    required int targetId,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/clients/merge',
        data: <String, Object?>{'source_id': sourceId, 'target_id': targetId},
      );
      final data = _unwrapMap(response.data);
      return data['merged'] == true;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ClientsPage _parseClientsPage(
    Object? body, {
    required int fallbackPage,
    required int fallbackPerPage,
  }) {
    if (body is! Map<Object?, Object?>) {
      throw const UgymApiException(
        code: 'INVALID_RESPONSE',
        message: 'Unexpected clients response format.',
      );
    }
    final rawList = body['data'];
    if (rawList is! List<Object?>) {
      throw const UgymApiException(
        code: 'INVALID_RESPONSE',
        message: 'Clients list payload is missing.',
      );
    }

    final items = rawList
        .map(_parseClientSummary)
        .whereType<ClientSummary>()
        .toList(growable: false);

    final meta = body['meta'];
    int page = fallbackPage;
    int perPage = fallbackPerPage;
    int total = items.length;
    if (meta is Map<Object?, Object?>) {
      page = _toInt(meta['page']) ?? fallbackPage;
      perPage = _toInt(meta['per_page']) ?? fallbackPerPage;
      total = _toInt(meta['total']) ?? items.length;
    }

    return ClientsPage(
      items: items,
      page: page,
      perPage: perPage,
      total: total,
    );
  }

  ClientSummary? _parseClientSummary(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final name = raw['name'];
    final phone = raw['phone'];
    if (id == null || name is! String || phone is! String) {
      return null;
    }
    final email = raw['email'];
    return ClientSummary(
      id: id,
      name: name,
      phone: phone,
      email: email is String ? email : null,
      linked: raw['linked'] == true,
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
