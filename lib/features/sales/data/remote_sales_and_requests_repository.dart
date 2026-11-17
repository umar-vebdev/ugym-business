import 'package:ugym_core/ugym_core.dart';

import '../domain/sales_and_requests_models.dart';

/// REST implementation of [SalesAndRequestsRepository] backed by `/api/v1/business`.
final class RemoteSalesAndRequestsRepository
    implements SalesAndRequestsRepository {
  const RemoteSalesAndRequestsRepository({required this.httpClient});

  final UgymHttpClient httpClient;

  @override
  Future<List<ProductItem>> listProducts({bool? onlyActive}) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/products',
        queryParameters: <String, Object?>{'only_active': ?onlyActive},
      );
      return _unwrapList(response.data)
          .map(_parseProduct)
          .whereType<ProductItem>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<int> createProduct({
    required String name,
    required int priceMinor,
    String? currency,
    int? stockQuantity,
  }) async {
    final trimmedCurrency = currency?.trim();
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/products',
        data: <String, Object?>{
          'name': name.trim(),
          'price_minor': priceMinor,
          if (trimmedCurrency != null && trimmedCurrency.isNotEmpty)
            'currency': trimmedCurrency.toUpperCase(),
          'stock_quantity': ?stockQuantity,
        },
      );
      final data = _unwrapMap(response.data);
      final id = _toInt(data['id']);
      if (id == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Created product ID is missing.',
        );
      }
      return id;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<ProductItem> updateProduct({
    required int productId,
    bool? isActive,
    int? stockQuantity,
  }) async {
    try {
      final response = await httpClient.dio.patch<Object?>(
        '/business/products/$productId',
        data: <String, Object?>{
          'is_active': ?isActive,
          'stock_quantity': ?stockQuantity,
        },
      );
      final product = _parseProduct(_unwrapMap(response.data));
      if (product == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Product payload is incomplete.',
        );
      }
      return product;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<SaleRecord>> listSales() async {
    return _fetchSales('/business/sales');
  }

  @override
  Future<List<SaleRecord>> listClientSales({required int clientId}) async {
    return _fetchSales('/business/clients/$clientId/sales');
  }

  Future<List<SaleRecord>> _fetchSales(String path) async {
    try {
      final response = await httpClient.dio.get<Object?>(path);
      return _unwrapList(response.data)
          .map(_parseSale)
          .whereType<SaleRecord>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<SaleRecord> registerSale({
    int? clientId,
    required PaymentMethod paymentMethod,
    List<SaleProductLineInput> products = const <SaleProductLineInput>[],
    List<int> membershipTypeIds = const <int>[],
    String? idempotencyKey,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/sales',
        data: <String, Object?>{
          'client_id': ?clientId,
          'payment_method': paymentMethod.apiValue,
          if (products.isNotEmpty)
            'products': products
                .map(
                  (p) => <String, Object?>{
                    'product_id': p.productId,
                    'quantity': p.quantity,
                  },
                )
                .toList(growable: false),
          if (membershipTypeIds.isNotEmpty)
            'membership_type_ids': membershipTypeIds,
        },
        options: UgymHttpClient.idempotentOptions(
          idempotencyKey: idempotencyKey,
        ),
      );
      final sale = _parseSale(_unwrapMap(response.data));
      if (sale == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Sale payload is incomplete.',
        );
      }
      return sale;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<SaleRecord> refundSale({
    required int saleId,
    required String reason,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/sales/$saleId/refund',
        data: <String, Object?>{'reason': reason.trim()},
      );
      final sale = _parseSale(_unwrapMap(response.data));
      if (sale == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Refunded sale payload is incomplete.',
        );
      }
      return sale;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<MembershipRequestRecord>> listMembershipRequests({
    MembershipRequestStatus? status,
  }) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/membership-requests',
        queryParameters: <String, Object?>{'status': ?status?.apiValue},
      );
      return _unwrapList(response.data)
          .map(_parseMembershipRequest)
          .whereType<MembershipRequestRecord>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<PayRequestResult> payMembershipRequest({
    required int requestId,
    required PaymentMethod paymentMethod,
    String? idempotencyKey,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/membership-requests/$requestId/pay',
        data: <String, Object?>{'payment_method': paymentMethod.apiValue},
        options: UgymHttpClient.idempotentOptions(
          idempotencyKey: idempotencyKey,
        ),
      );
      final data = _unwrapMap(response.data);
      final parsedRequestId = _toInt(data['request_id']);
      final saleId = _toInt(data['sale_id']);
      final membershipId = _toInt(data['membership_id']);
      final clientId = _toInt(data['client_id']);
      final paidAt = _toDateTime(data['paid_at']);
      if (parsedRequestId == null ||
          saleId == null ||
          membershipId == null ||
          clientId == null ||
          paidAt == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Pay request payload is incomplete.',
        );
      }
      return PayRequestResult(
        requestId: parsedRequestId,
        saleId: saleId,
        membershipId: membershipId,
        clientId: clientId,
        status: MembershipRequestStatus.fromApi(_asString(data['status'])),
        paidAt: paidAt,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<MembershipRequestStatus> cancelMembershipRequest({
    required int requestId,
    String? reason,
  }) async {
    final trimmedReason = reason?.trim();
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/membership-requests/$requestId/cancel',
        data: <String, Object?>{
          if (trimmedReason != null && trimmedReason.isNotEmpty)
            'reason': trimmedReason,
        },
      );
      final data = _unwrapMap(response.data);
      return MembershipRequestStatus.fromApi(_asString(data['status']));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ProductItem? _parseProduct(Object? raw) {
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
    return ProductItem(
      id: id,
      name: name,
      priceMinor: priceMinor,
      currency: currency,
      stockQuantity: _toInt(raw['stock_quantity']),
      isActive: raw['is_active'] == true,
    );
  }

  SaleRecord? _parseSale(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final companyId = _toInt(raw['company_id']);
    final totalMinor = _toInt(raw['total_minor']);
    final currency = _asString(raw['currency']);
    final acceptedByUserId = _toInt(raw['accepted_by_user_id']);
    final paidAt = _toDateTime(raw['paid_at']);
    if (id == null ||
        companyId == null ||
        totalMinor == null ||
        currency == null ||
        acceptedByUserId == null ||
        paidAt == null) {
      return null;
    }

    final rawItems = raw['items'];
    final items = rawItems is List<Object?>
        ? rawItems
              .map(_parseSaleItem)
              .whereType<SaleItemRecord>()
              .toList(growable: false)
        : const <SaleItemRecord>[];

    return SaleRecord(
      id: id,
      companyId: companyId,
      clientId: _toInt(raw['client_id']),
      status: SaleStatus.fromApi(_asString(raw['status'])),
      paymentMethod: PaymentMethod.fromApi(_asString(raw['payment_method'])),
      totalMinor: totalMinor,
      currency: currency,
      acceptedByUserId: acceptedByUserId,
      paidAt: paidAt,
      refundReason: _asString(raw['refund_reason']),
      refundedByUserId: _toInt(raw['refunded_by_user_id']),
      refundedAt: _toDateTime(raw['refunded_at']),
      items: items,
    );
  }

  SaleItemRecord? _parseSaleItem(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final name = _asString(raw['name']);
    final unitPriceMinor = _toInt(raw['unit_price_minor']);
    final currency = _asString(raw['currency']);
    final quantity = _toInt(raw['quantity']);
    final lineTotalMinor = _toInt(raw['line_total_minor']);
    if (name == null ||
        unitPriceMinor == null ||
        currency == null ||
        quantity == null ||
        lineTotalMinor == null) {
      return null;
    }
    return SaleItemRecord(
      name: name,
      unitPriceMinor: unitPriceMinor,
      currency: currency,
      quantity: quantity,
      lineTotalMinor: lineTotalMinor,
      productId: _toInt(raw['product_id']),
      membershipTypeId: _toInt(raw['membership_type_id']),
      issuedMembershipId: _toInt(raw['issued_membership_id']),
    );
  }

  MembershipRequestRecord? _parseMembershipRequest(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final companyId = _toInt(raw['company_id']);
    final gymId = _toInt(raw['gym_id']);
    final userId = _toInt(raw['user_id']);
    final membershipTypeId = _toInt(raw['membership_type_id']);
    final expiresAt = _toDateTime(raw['expires_at']);
    if (id == null ||
        companyId == null ||
        gymId == null ||
        userId == null ||
        membershipTypeId == null ||
        expiresAt == null) {
      return null;
    }
    return MembershipRequestRecord(
      id: id,
      companyId: companyId,
      gymId: gymId,
      userId: userId,
      clientId: _toInt(raw['client_id']),
      membershipTypeId: membershipTypeId,
      status: MembershipRequestStatus.fromApi(_asString(raw['status'])),
      expiresAt: expiresAt,
      createdAt: _toDateTime(raw['created_at']),
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
