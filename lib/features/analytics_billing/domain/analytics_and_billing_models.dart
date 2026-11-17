/// Delivery channel for bulk company announcements.
enum AnnouncementChannel {
  push('push'),
  sms('sms');

  const AnnouncementChannel(this.apiValue);

  final String apiValue;

  static AnnouncementChannel fromApi(String? raw) {
    return switch (raw) {
      'sms' => AnnouncementChannel.sms,
      _ => AnnouncementChannel.push,
    };
  }
}

/// Billing cycle of a platform subscription plan.
enum BillingPlanPeriod {
  month('month'),
  year('year');

  const BillingPlanPeriod(this.apiValue);

  final String apiValue;

  static BillingPlanPeriod fromApi(String? raw) {
    return switch (raw) {
      'year' => BillingPlanPeriod.year,
      _ => BillingPlanPeriod.month,
    };
  }
}

/// Company platform subscription status.
enum CompanySubscriptionStatus {
  trial('trial'),
  active('active'),
  expired('expired');

  const CompanySubscriptionStatus(this.apiValue);

  final String apiValue;

  static CompanySubscriptionStatus fromApi(String? raw) {
    return switch (raw) {
      'active' => CompanySubscriptionStatus.active,
      'expired' => CompanySubscriptionStatus.expired,
      _ => CompanySubscriptionStatus.trial,
    };
  }
}

/// Breakdown of revenue in minor units by payment method.
final class RevenueByPaymentMethod {
  const RevenueByPaymentMethod({
    required this.cash,
    required this.cardTerminal,
    required this.transfer,
  });

  final int cash;
  final int cardTerminal;
  final int transfer;
}

/// Revenue summary shared by overview and revenue reports.
final class RevenueSummary {
  const RevenueSummary({
    required this.totalMinor,
    required this.membershipsMinor,
    required this.productsMinor,
    required this.byPaymentMethod,
    required this.salesCount,
    required this.currency,
  });

  final int totalMinor;
  final int membershipsMinor;
  final int productsMinor;
  final RevenueByPaymentMethod byPaymentMethod;
  final int salesCount;
  final String currency;
}

/// Revenue report for a `[from, to]` date range.
final class RevenueReport {
  const RevenueReport({
    required this.from,
    required this.to,
    required this.summary,
  });

  final String from;
  final String to;
  final RevenueSummary summary;
}

/// Top-selling membership or product entry.
final class ItemPopularity {
  const ItemPopularity({
    required this.itemId,
    required this.name,
    required this.soldCount,
    required this.revenueMinor,
    required this.currency,
  });

  final int itemId;
  final String name;
  final int soldCount;
  final int revenueMinor;
  final String currency;
}

/// Client metrics inside [OverviewAnalytics].
final class ClientsAnalyticsSummary {
  const ClientsAnalyticsSummary({
    required this.totalClients,
    required this.newClients,
    required this.existingClients,
  });

  final int totalClients;
  final int newClients;
  final int existingClients;
}

/// Visit metrics and daily chart data inside [OverviewAnalytics].
final class VisitsAnalyticsSummary {
  const VisitsAnalyticsSummary({
    required this.totalVisits,
    required this.qrVisits,
    required this.manualVisits,
    required this.byDay,
    required this.inactiveDaysThreshold,
    required this.inactiveClientsCount,
  });

  final int totalVisits;
  final int qrVisits;
  final int manualVisits;
  final Map<String, int> byDay;
  final int inactiveDaysThreshold;
  final int inactiveClientsCount;
}

/// Combined owner overview analytics for a date range.
final class OverviewAnalytics {
  const OverviewAnalytics({
    required this.from,
    required this.to,
    required this.revenue,
    required this.clients,
    required this.visits,
    required this.popularMemberships,
    required this.popularProducts,
  });

  final String from;
  final String to;
  final RevenueSummary revenue;
  final ClientsAnalyticsSummary clients;
  final VisitsAnalyticsSummary visits;
  final List<ItemPopularity> popularMemberships;
  final List<ItemPopularity> popularProducts;
}

/// Result of queuing a bulk announcement (`202 Accepted`).
final class AnnouncementQueuedResult {
  const AnnouncementQueuedResult({
    required this.queuedCount,
    required this.channel,
  });

  final int queuedCount;
  final AnnouncementChannel channel;
}

/// Active platform subscription plan for fitness clubs.
final class PlatformPlan {
  const PlatformPlan({
    required this.id,
    required this.name,
    required this.period,
    required this.priceMinor,
    required this.currency,
    required this.maxGyms,
    required this.maxStaff,
    required this.isActive,
  });

  final int id;
  final String name;
  final BillingPlanPeriod period;
  final int priceMinor;
  final String currency;
  final int maxGyms;
  final int maxStaff;
  final bool isActive;
}

/// Current platform subscription (or trial) state of the company.
final class CompanySubscription {
  const CompanySubscription({
    required this.id,
    required this.companyId,
    required this.status,
    required this.isReadOnly,
    required this.startsAt,
    required this.endsAt,
    this.planId,
  });

  final int id;
  final int companyId;
  final int? planId;
  final CompanySubscriptionStatus status;
  final bool isReadOnly;
  final DateTime startsAt;
  final DateTime endsAt;
}

/// Contract for analytics, announcements, and platform billing status.
abstract interface class AnalyticsAndBillingRepository {
  Future<OverviewAnalytics> fetchOverview({
    String? from,
    String? to,
    int inactiveDays = 14,
  });

  Future<RevenueReport> fetchRevenueReport({String? from, String? to});

  Future<AnnouncementQueuedResult> sendAnnouncement({
    required AnnouncementChannel channel,
    required String title,
    required String body,
  });

  Future<List<PlatformPlan>> listBillingPlans();

  Future<CompanySubscription> fetchBillingSubscription();
}
