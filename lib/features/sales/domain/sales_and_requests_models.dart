/// Payment method recorded in PaymentMark (no online payment processing).
enum PaymentMethod {
  cash('cash'),
  cardTerminal('card_terminal'),
  transfer('transfer');

  const PaymentMethod(this.apiValue);

  final String apiValue;

  static PaymentMethod fromApi(String? raw) {
    return switch (raw) {
      'card_terminal' => PaymentMethod.cardTerminal,
      'transfer' => PaymentMethod.transfer,
      _ => PaymentMethod.cash,
    };
  }
}

/// Lifecycle status of a sale receipt.
enum SaleStatus {
  paid('paid'),
  refunded('refunded'),
  cancelled('cancelled');

  const SaleStatus(this.apiValue);

  final String apiValue;

  static SaleStatus fromApi(String? raw) {
    return switch (raw) {
      'refunded' => SaleStatus.refunded,
      'cancelled' => SaleStatus.cancelled,
      _ => SaleStatus.paid,
    };
  }
}

/// Status of a client membership purchase request.
enum MembershipRequestStatus {
  pending('pending'),
  paid('paid'),
  cancelled('cancelled'),
  expired('expired');

  const MembershipRequestStatus(this.apiValue);

  final String apiValue;

  static MembershipRequestStatus fromApi(String? raw) {
    return switch (raw) {
      'paid' => MembershipRequestStatus.paid,
      'cancelled' => MembershipRequestStatus.cancelled,
      'expired' => MembershipRequestStatus.expired,
      _ => MembershipRequestStatus.pending,
    };
  }
}

/// Product sold at reception.
final class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    required this.priceMinor,
    required this.currency,
    required this.isActive,
    this.stockQuantity,
  });

  final int id;
  final String name;
  final int priceMinor;
  final String currency;
  final int? stockQuantity;
  final bool isActive;
}

/// Product quantity line submitted when registering a sale.
final class SaleProductLineInput {
  const SaleProductLineInput({required this.productId, required this.quantity});

  final int productId;
  final int quantity;
}

/// Line item inside a completed sale receipt.
final class SaleItemRecord {
  const SaleItemRecord({
    required this.name,
    required this.unitPriceMinor,
    required this.currency,
    required this.quantity,
    required this.lineTotalMinor,
    this.productId,
    this.membershipTypeId,
    this.issuedMembershipId,
  });

  final String name;
  final int unitPriceMinor;
  final String currency;
  final int quantity;
  final int lineTotalMinor;
  final int? productId;
  final int? membershipTypeId;
  final int? issuedMembershipId;
}

/// Recorded PaymentMark sale with items and optional refund metadata.
final class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.companyId,
    required this.status,
    required this.paymentMethod,
    required this.totalMinor,
    required this.currency,
    required this.acceptedByUserId,
    required this.paidAt,
    required this.items,
    this.clientId,
    this.refundReason,
    this.refundedByUserId,
    this.refundedAt,
  });

  final int id;
  final int companyId;
  final int? clientId;
  final SaleStatus status;
  final PaymentMethod paymentMethod;
  final int totalMinor;
  final String currency;
  final int acceptedByUserId;
  final DateTime paidAt;
  final String? refundReason;
  final int? refundedByUserId;
  final DateTime? refundedAt;
  final List<SaleItemRecord> items;
}

/// Incoming client membership purchase request awaiting PaymentMark.
final class MembershipRequestRecord {
  const MembershipRequestRecord({
    required this.id,
    required this.companyId,
    required this.gymId,
    required this.userId,
    required this.membershipTypeId,
    required this.status,
    required this.expiresAt,
    this.clientId,
    this.createdAt,
  });

  final int id;
  final int companyId;
  final int gymId;
  final int userId;
  final int? clientId;
  final int membershipTypeId;
  final MembershipRequestStatus status;
  final DateTime expiresAt;
  final DateTime? createdAt;
}

/// Result returned when staff confirms payment for a membership request.
final class PayRequestResult {
  const PayRequestResult({
    required this.requestId,
    required this.saleId,
    required this.membershipId,
    required this.clientId,
    required this.status,
    required this.paidAt,
  });

  final int requestId;
  final int saleId;
  final int membershipId;
  final int clientId;
  final MembershipRequestStatus status;
  final DateTime paidAt;
}

/// Contract for POS sales, refunds, products, and client membership requests.
abstract interface class SalesAndRequestsRepository {
  Future<List<ProductItem>> listProducts({bool? onlyActive});

  Future<int> createProduct({
    required String name,
    required int priceMinor,
    String? currency,
    int? stockQuantity,
  });

  Future<ProductItem> updateProduct({
    required int productId,
    bool? isActive,
    int? stockQuantity,
  });

  Future<List<SaleRecord>> listSales();

  Future<List<SaleRecord>> listClientSales({required int clientId});

  Future<SaleRecord> registerSale({
    int? clientId,
    required PaymentMethod paymentMethod,
    List<SaleProductLineInput> products = const <SaleProductLineInput>[],
    List<int> membershipTypeIds = const <int>[],
    String? idempotencyKey,
  });

  Future<SaleRecord> refundSale({required int saleId, required String reason});

  Future<List<MembershipRequestRecord>> listMembershipRequests({
    MembershipRequestStatus? status,
  });

  Future<PayRequestResult> payMembershipRequest({
    required int requestId,
    required PaymentMethod paymentMethod,
    String? idempotencyKey,
  });

  Future<MembershipRequestStatus> cancelMembershipRequest({
    required int requestId,
    String? reason,
  });
}
