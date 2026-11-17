import 'package:ugym_core/ugym_core.dart';

import '../domain/analytics_and_billing_models.dart';

/// REST implementation of [AnalyticsAndBillingRepository] backed by `/api/v1/business`.
final class RemoteAnalyticsAndBillingRepository
    implements AnalyticsAndBillingRepository {
  const RemoteAnalyticsAndBillingRepository({required this.httpClient});

  final UgymHttpClient httpClient;

  @override
  Future<OverviewAnalytics> fetchOverview({
    String? from,
    String? to,
    int inactiveDays = 14,
  }) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/analytics/overview',
        queryParameters: <String, Object?>{
          'from': ?_trimOrNull(from),
          'to': ?_trimOrNull(to),
          'inactive_days': inactiveDays,
        },
      );
      final data = _unwrapMap(response.data);
      final parsedFrom = _asString(data['from']) ?? '';
      final parsedTo = _asString(data['to']) ?? '';
      final revenue = _parseRevenueSummary(data['revenue']);
      final clients = _parseClients(data['clients']);
      final visits = _parseVisits(data['visits']);

      if (revenue == null || clients == null || visits == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Overview analytics payload is incomplete.',
        );
      }

      return OverviewAnalytics(
        from: parsedFrom,
        to: parsedTo,
        revenue: revenue,
        clients: clients,
        visits: visits,
        popularMemberships: _parsePopularityList(data['popular_memberships']),
        popularProducts: _parsePopularityList(data['popular_products']),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<RevenueReport> fetchRevenueReport({String? from, String? to}) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/analytics/revenue',
        queryParameters: <String, Object?>{
          'from': ?_trimOrNull(from),
          'to': ?_trimOrNull(to),
        },
      );
      final data = _unwrapMap(response.data);
      final summary = _parseRevenueSummary(data);
      if (summary == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Revenue report payload is incomplete.',
        );
      }
      return RevenueReport(
        from: _asString(data['from']) ?? '',
        to: _asString(data['to']) ?? '',
        summary: summary,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<AnnouncementQueuedResult> sendAnnouncement({
    required AnnouncementChannel channel,
    required String title,
    required String body,
  }) async {
    try {
      final response = await httpClient.dio.post<Object?>(
        '/business/notifications/announcements',
        data: <String, Object?>{
          'channel': channel.apiValue,
          'title': title.trim(),
          'body': body.trim(),
        },
      );
      final data = _unwrapMap(response.data);
      final queuedCount = _toInt(data['queued_count']);
      if (queuedCount == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Announcement response payload is incomplete.',
        );
      }
      return AnnouncementQueuedResult(
        queuedCount: queuedCount,
        channel: AnnouncementChannel.fromApi(_asString(data['channel'])),
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<PlatformPlan>> listBillingPlans() async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/billing/plans',
      );
      return _unwrapList(response.data)
          .map(_parsePlan)
          .whereType<PlatformPlan>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CompanySubscription> fetchBillingSubscription() async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/billing/subscription',
      );
      final data = _unwrapMap(response.data);
      final id = _toInt(data['id']);
      final companyId = _toInt(data['company_id']);
      final startsAt = _toDateTime(data['starts_at']);
      final endsAt = _toDateTime(data['ends_at']);
      if (id == null ||
          companyId == null ||
          startsAt == null ||
          endsAt == null) {
        throw const UgymApiException(
          code: 'INVALID_RESPONSE',
          message: 'Subscription payload is incomplete.',
        );
      }
      return CompanySubscription(
        id: id,
        companyId: companyId,
        planId: _toInt(data['plan_id']),
        status: CompanySubscriptionStatus.fromApi(_asString(data['status'])),
        isReadOnly: data['is_read_only'] == true,
        startsAt: startsAt,
        endsAt: endsAt,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  RevenueSummary? _parseRevenueSummary(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final totalMinor = _toInt(raw['total_minor']);
    final membershipsMinor = _toInt(raw['memberships_minor']);
    final productsMinor = _toInt(raw['products_minor']);
    final salesCount = _toInt(raw['sales_count']);
    final currency = _asString(raw['currency']);
    final methods = raw['by_payment_method'];
    if (totalMinor == null ||
        membershipsMinor == null ||
        productsMinor == null ||
        salesCount == null ||
        currency == null ||
        methods is! Map<Object?, Object?>) {
      return null;
    }
    return RevenueSummary(
      totalMinor: totalMinor,
      membershipsMinor: membershipsMinor,
      productsMinor: productsMinor,
      byPaymentMethod: RevenueByPaymentMethod(
        cash: _toInt(methods['cash']) ?? 0,
        cardTerminal: _toInt(methods['card_terminal']) ?? 0,
        transfer: _toInt(methods['transfer']) ?? 0,
      ),
      salesCount: salesCount,
      currency: currency,
    );
  }

  ClientsAnalyticsSummary? _parseClients(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final totalClients = _toInt(raw['total_clients']);
    final newClients = _toInt(raw['new_clients']);
    final existingClients = _toInt(raw['existing_clients']);
    if (totalClients == null || newClients == null || existingClients == null) {
      return null;
    }
    return ClientsAnalyticsSummary(
      totalClients: totalClients,
      newClients: newClients,
      existingClients: existingClients,
    );
  }

  VisitsAnalyticsSummary? _parseVisits(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final totalVisits = _toInt(raw['total_visits']);
    final qrVisits = _toInt(raw['qr_visits']);
    final manualVisits = _toInt(raw['manual_visits']);
    final threshold = _toInt(raw['inactive_days_threshold']);
    final inactiveCount = _toInt(raw['inactive_clients_count']);
    if (totalVisits == null ||
        qrVisits == null ||
        manualVisits == null ||
        threshold == null ||
        inactiveCount == null) {
      return null;
    }

    final byDay = <String, int>{};
    final rawByDay = raw['by_day'];
    if (rawByDay is Map<Object?, Object?>) {
      for (final entry in rawByDay.entries) {
        final key = entry.key;
        final val = _toInt(entry.value);
        if (key is String && val != null) {
          byDay[key] = val;
        }
      }
    }

    return VisitsAnalyticsSummary(
      totalVisits: totalVisits,
      qrVisits: qrVisits,
      manualVisits: manualVisits,
      byDay: byDay,
      inactiveDaysThreshold: threshold,
      inactiveClientsCount: inactiveCount,
    );
  }

  List<ItemPopularity> _parsePopularityList(Object? raw) {
    if (raw is! List<Object?>) {
      return const <ItemPopularity>[];
    }
    final result = <ItemPopularity>[];
    for (final item in raw) {
      if (item is! Map<Object?, Object?>) {
        continue;
      }
      final itemId = _toInt(item['item_id']);
      final name = _asString(item['name']);
      final soldCount = _toInt(item['sold_count']);
      final revenueMinor = _toInt(item['revenue_minor']);
      final currency = _asString(item['currency']);
      if (itemId == null ||
          name == null ||
          soldCount == null ||
          revenueMinor == null ||
          currency == null) {
        continue;
      }
      result.add(
        ItemPopularity(
          itemId: itemId,
          name: name,
          soldCount: soldCount,
          revenueMinor: revenueMinor,
          currency: currency,
        ),
      );
    }
    return result;
  }

  PlatformPlan? _parsePlan(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final id = _toInt(raw['id']);
    final name = _asString(raw['name']);
    final priceMinor = _toInt(raw['price_minor']);
    final currency = _asString(raw['currency']);
    final maxGyms = _toInt(raw['max_gyms']);
    final maxStaff = _toInt(raw['max_staff']);
    if (id == null ||
        name == null ||
        priceMinor == null ||
        currency == null ||
        maxGyms == null ||
        maxStaff == null) {
      return null;
    }
    return PlatformPlan(
      id: id,
      name: name,
      period: BillingPlanPeriod.fromApi(_asString(raw['period'])),
      priceMinor: priceMinor,
      currency: currency,
      maxGyms: maxGyms,
      maxStaff: maxStaff,
      isActive: raw['is_active'] == true,
    );
  }

  String? _trimOrNull(String? raw) {
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
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
