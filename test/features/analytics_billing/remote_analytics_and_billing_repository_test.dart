import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/network/business_api_client.dart';
import 'package:ugym_business/features/analytics_billing/data/remote_analytics_and_billing_repository.dart';
import 'package:ugym_business/features/analytics_billing/domain/analytics_and_billing_models.dart';
import 'package:ugym_core/ugym_core.dart';

final class _MockAnalyticsAdapter implements HttpClientAdapter {
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
  late _MockAnalyticsAdapter adapter;
  late RemoteAnalyticsAndBillingRepository repository;

  setUp(() {
    adapter = _MockAnalyticsAdapter();
    final apiClient = BusinessApiClient(
      config: const AppConfig.dev(),
      tokenStorage: InMemoryTokenStorage(),
    );
    apiClient.httpClient.dio.httpClientAdapter = adapter;
    repository = RemoteAnalyticsAndBillingRepository(
      httpClient: apiClient.httpClient,
    );
  });

  test('fetchOverview and fetchRevenueReport parse metrics properly', () async {
    adapter.nextStatusCode = 200;
    adapter.nextBody = {
      'data': {
        'from': '2026-11-01',
        'to': '2026-11-17',
        'revenue': {
          'total_minor': 50000,
          'memberships_minor': 45000,
          'products_minor': 5000,
          'by_payment_method': {
            'cash': 30000,
            'card_terminal': 15000,
            'transfer': 5000,
          },
          'sales_count': 4,
          'currency': 'TJS',
        },
        'clients': {
          'total_clients': 120,
          'new_clients': 15,
          'existing_clients': 105,
        },
        'visits': {
          'total_visits': 240,
          'qr_visits': 220,
          'manual_visits': 20,
          'by_day': {'2026-11-16': 18, '2026-11-17': 22},
          'inactive_days_threshold': 14,
          'inactive_clients_count': 12,
        },
        'popular_memberships': [
          {
            'item_id': 3,
            'name': 'Безлимит 30',
            'sold_count': 10,
            'revenue_minor': 45000,
            'currency': 'TJS',
          },
        ],
        'popular_products': const <Object>[],
      },
    };

    final overview = await repository.fetchOverview(
      from: '2026-11-01',
      to: '2026-11-17',
      inactiveDays: 21,
    );
    expect(adapter.lastRequest?.queryParameters, {
      'from': '2026-11-01',
      'to': '2026-11-17',
      'inactive_days': 21,
    });
    expect(overview.revenue.totalMinor, 50000);
    expect(overview.revenue.byPaymentMethod.cardTerminal, 15000);
    expect(overview.visits.byDay['2026-11-17'], 22);
    expect(overview.popularMemberships.single.name, 'Безлимит 30');

    adapter.nextBody = {
      'data': {
        'from': '2026-11-01',
        'to': '2026-11-17',
        'total_minor': 50000,
        'memberships_minor': 45000,
        'products_minor': 5000,
        'by_payment_method': {
          'cash': 30000,
          'card_terminal': 15000,
          'transfer': 5000,
        },
        'sales_count': 4,
        'currency': 'TJS',
      },
    };
    final revenue = await repository.fetchRevenueReport(
      from: '2026-11-01',
      to: '2026-11-17',
    );
    expect(revenue.summary.salesCount, 4);
    expect(revenue.summary.byPaymentMethod.cash, 30000);
  });

  test(
    'sendAnnouncement handles 202 Accepted and queues notifications',
    () async {
      adapter.nextStatusCode = 202;
      adapter.nextBody = {
        'data': {'queued_count': 25, 'channel': 'push'},
      };

      final result = await repository.sendAnnouncement(
        channel: AnnouncementChannel.push,
        title: 'График',
        body: 'Работаем до 22:00',
      );
      expect(
        adapter.lastRequest?.path,
        '/business/notifications/announcements',
      );
      expect(adapter.lastData, {
        'channel': 'push',
        'title': 'График',
        'body': 'Работаем до 22:00',
      });
      expect(result.queuedCount, 25);
      expect(result.channel, AnnouncementChannel.push);
    },
  );

  test(
    'listBillingPlans and fetchBillingSubscription parse platform data',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': [
          {
            'id': 1,
            'name': 'Start',
            'period': 'month',
            'price_minor': 19900,
            'currency': 'TJS',
            'max_gyms': 2,
            'max_staff': 10,
            'is_active': true,
          },
        ],
      };

      final plans = await repository.listBillingPlans();
      expect(plans.single.period, BillingPlanPeriod.month);
      expect(plans.single.maxGyms, 2);

      adapter.nextBody = {
        'data': {
          'id': 9,
          'company_id': 1,
          'plan_id': 1,
          'status': 'trial',
          'is_read_only': false,
          'starts_at': '2026-11-01T00:00:00Z',
          'ends_at': '2026-11-15T00:00:00Z',
        },
      };
      final sub = await repository.fetchBillingSubscription();
      expect(sub.status, CompanySubscriptionStatus.trial);
      expect(sub.isReadOnly, isFalse);
      expect(sub.planId, 1);
    },
  );
}
