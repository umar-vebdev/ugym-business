import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/network/business_api_client.dart';
import 'package:ugym_business/features/sales/data/remote_sales_and_requests_repository.dart';
import 'package:ugym_business/features/sales/domain/sales_and_requests_models.dart';
import 'package:ugym_core/ugym_core.dart';

final class _MockSalesAdapter implements HttpClientAdapter {
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
  late _MockSalesAdapter adapter;
  late RemoteSalesAndRequestsRepository repository;

  setUp(() {
    adapter = _MockSalesAdapter();
    final apiClient = BusinessApiClient(
      config: const AppConfig.dev(),
      tokenStorage: InMemoryTokenStorage(),
    );
    apiClient.httpClient.dio.httpClientAdapter = adapter;
    repository = RemoteSalesAndRequestsRepository(
      httpClient: apiClient.httpClient,
    );
  });

  test(
    'listProducts, createProduct, and updateProduct work as expected',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': [
          {
            'id': 4,
            'name': 'Вода 0.5л',
            'price_minor': 500,
            'currency': 'TJS',
            'stock_quantity': 24,
            'is_active': true,
          },
        ],
      };

      final products = await repository.listProducts(onlyActive: true);
      expect(adapter.lastRequest?.queryParameters, {'only_active': true});
      expect(products.single.name, 'Вода 0.5л');
      expect(products.single.stockQuantity, 24);

      adapter.nextStatusCode = 201;
      adapter.nextBody = {
        'data': {'id': 5},
      };
      final createdId = await repository.createProduct(
        name: 'Шейкер',
        priceMinor: 4500,
        stockQuantity: 10,
      );
      expect(createdId, 5);
      expect(adapter.lastData, {
        'name': 'Шейкер',
        'price_minor': 4500,
        'stock_quantity': 10,
      });

      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': {
          'id': 5,
          'name': 'Шейкер',
          'price_minor': 4500,
          'currency': 'TJS',
          'stock_quantity': 15,
          'is_active': false,
        },
      };
      final updated = await repository.updateProduct(
        productId: 5,
        isActive: false,
        stockQuantity: 15,
      );
      expect(updated.isActive, isFalse);
      expect(updated.stockQuantity, 15);
    },
  );

  test(
    'registerSale sends Idempotency-Key and parses SaleRecord with items',
    () async {
      adapter.nextStatusCode = 201;
      adapter.nextBody = {
        'data': {
          'id': 70,
          'company_id': 1,
          'client_id': 11,
          'status': 'paid',
          'payment_method': 'card_terminal',
          'total_minor': 25500,
          'currency': 'TJS',
          'accepted_by_user_id': 2,
          'paid_at': '2026-11-17T11:00:00Z',
          'items': [
            {
              'name': 'Вода 0.5л',
              'unit_price_minor': 500,
              'currency': 'TJS',
              'quantity': 1,
              'line_total_minor': 500,
              'product_id': 4,
            },
            {
              'name': 'Безлимит 30 дней',
              'unit_price_minor': 25000,
              'currency': 'TJS',
              'quantity': 1,
              'line_total_minor': 25000,
              'membership_type_id': 3,
              'issued_membership_id': 51,
            },
          ],
        },
      };

      final sale = await repository.registerSale(
        clientId: 11,
        paymentMethod: PaymentMethod.cardTerminal,
        products: const [SaleProductLineInput(productId: 4, quantity: 1)],
        membershipTypeIds: const [3],
        idempotencyKey: 'idem-sale-1',
      );

      expect(adapter.lastRequest?.headers['Idempotency-Key'], 'idem-sale-1');
      expect(sale.paymentMethod, PaymentMethod.cardTerminal);
      expect(sale.totalMinor, 25500);
      expect(sale.items, hasLength(2));
      expect(sale.items.last.issuedMembershipId, 51);
    },
  );

  test('refundSale sends reason and returns refunded SaleRecord', () async {
    adapter.nextStatusCode = 200;
    adapter.nextBody = {
      'data': {
        'id': 70,
        'company_id': 1,
        'status': 'refunded',
        'payment_method': 'cash',
        'total_minor': 500,
        'currency': 'TJS',
        'accepted_by_user_id': 2,
        'paid_at': '2026-11-17T11:00:00Z',
        'refund_reason': 'Ошибочный чек',
        'items': const <Object>[],
      },
    };

    final refunded = await repository.refundSale(
      saleId: 70,
      reason: 'Ошибочный чек',
    );

    expect(adapter.lastRequest?.path, '/business/sales/70/refund');
    expect(adapter.lastData, {'reason': 'Ошибочный чек'});
    expect(refunded.status, SaleStatus.refunded);
    expect(refunded.refundReason, 'Ошибочный чек');
  });

  test(
    'membership requests list, pay with Idempotency-Key, and cancel work',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': [
          {
            'id': 81,
            'company_id': 1,
            'gym_id': 10,
            'user_id': 5,
            'client_id': 11,
            'membership_type_id': 3,
            'status': 'pending',
            'expires_at': '2026-11-18T11:00:00Z',
          },
        ],
      };

      final requests = await repository.listMembershipRequests(
        status: MembershipRequestStatus.pending,
      );
      expect(adapter.lastRequest?.queryParameters, {'status': 'pending'});
      expect(requests.single.id, 81);

      adapter.nextBody = {
        'data': {
          'request_id': 81,
          'sale_id': 71,
          'membership_id': 52,
          'client_id': 11,
          'status': 'paid',
          'paid_at': '2026-11-17T12:00:00Z',
        },
      };
      final paid = await repository.payMembershipRequest(
        requestId: 81,
        paymentMethod: PaymentMethod.transfer,
        idempotencyKey: 'idem-pay-81',
      );
      expect(adapter.lastRequest?.headers['Idempotency-Key'], 'idem-pay-81');
      expect(paid.saleId, 71);
      expect(paid.membershipId, 52);

      adapter.nextBody = {
        'data': {'id': 82, 'status': 'cancelled'},
      };
      final cancelledStatus = await repository.cancelMembershipRequest(
        requestId: 82,
        reason: 'Клиент передумал',
      );
      expect(cancelledStatus, MembershipRequestStatus.cancelled);
    },
  );
}
