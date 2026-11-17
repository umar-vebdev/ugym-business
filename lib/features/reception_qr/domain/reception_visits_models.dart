/// Visit registration method returned by the Visits API.
enum VisitMethod {
  qr,
  clientQr,
  manual;

  static VisitMethod fromApi(String? raw) {
    return switch (raw) {
      'client_qr' => VisitMethod.clientQr,
      'manual' => VisitMethod.manual,
      _ => VisitMethod.qr,
    };
  }
}

/// Lifecycle status of a registered gym visit.
enum VisitStatus {
  completed,
  cancelled;

  static VisitStatus fromApi(String? raw) {
    return switch (raw) {
      'cancelled' => VisitStatus.cancelled,
      _ => VisitStatus.completed,
    };
  }
}

/// Dynamic 60-second HMAC QR payload displayed on the reception kiosk screen.
final class GymQrToken {
  const GymQrToken({
    required this.gymId,
    required this.gymName,
    required this.slot,
    required this.token,
    required this.ttlSeconds,
    required this.expiresAt,
  });

  final int gymId;
  final String gymName;
  final int slot;
  final String token;
  final int ttlSeconds;
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymQrToken &&
          runtimeType == other.runtimeType &&
          gymId == other.gymId &&
          gymName == other.gymName &&
          slot == other.slot &&
          token == other.token &&
          ttlSeconds == other.ttlSeconds &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode =>
      Object.hash(gymId, gymName, slot, token, ttlSeconds, expiresAt);
}

/// Result of a QR or manual check-in returned by the server.
final class CheckInResult {
  const CheckInResult({
    required this.id,
    required this.companyId,
    required this.gymId,
    required this.clientId,
    required this.membershipId,
    required this.method,
    required this.status,
    required this.visitedAt,
    required this.visitDate,
    this.remainingVisits,
  });

  final int id;
  final int companyId;
  final int gymId;
  final int clientId;
  final int membershipId;
  final VisitMethod method;
  final VisitStatus status;
  final DateTime visitedAt;
  final String visitDate;
  final int? remainingVisits;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          companyId == other.companyId &&
          gymId == other.gymId &&
          clientId == other.clientId &&
          membershipId == other.membershipId &&
          method == other.method &&
          status == other.status &&
          visitedAt == other.visitedAt &&
          visitDate == other.visitDate &&
          remainingVisits == other.remainingVisits;

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    gymId,
    clientId,
    membershipId,
    method,
    status,
    visitedAt,
    visitDate,
    remainingVisits,
  );
}

/// Visit log item with 24-hour cancellation eligibility helper.
final class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.companyId,
    required this.gymId,
    required this.clientId,
    required this.membershipId,
    required this.method,
    required this.status,
    required this.visitedAt,
    required this.visitDate,
    this.registeredByUserId,
    this.cancelReason,
    this.cancelledByUserId,
    this.cancelledAt,
  });

  final int id;
  final int companyId;
  final int gymId;
  final int clientId;
  final int membershipId;
  final VisitMethod method;
  final VisitStatus status;
  final DateTime visitedAt;
  final String visitDate;
  final int? registeredByUserId;
  final String? cancelReason;
  final int? cancelledByUserId;
  final DateTime? cancelledAt;

  /// Staff may cancel completed visits within 24 hours from check-in.
  bool canCancelAt(DateTime nowUtc) {
    if (status != VisitStatus.completed) {
      return false;
    }
    return nowUtc.toUtc().difference(visitedAt.toUtc()) <=
        const Duration(hours: 24);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          companyId == other.companyId &&
          gymId == other.gymId &&
          clientId == other.clientId &&
          membershipId == other.membershipId &&
          method == other.method &&
          status == other.status &&
          visitedAt == other.visitedAt &&
          visitDate == other.visitDate &&
          registeredByUserId == other.registeredByUserId &&
          cancelReason == other.cancelReason &&
          cancelledByUserId == other.cancelledByUserId &&
          cancelledAt == other.cancelledAt;

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    gymId,
    clientId,
    membershipId,
    method,
    status,
    visitedAt,
    visitDate,
    registeredByUserId,
    cancelReason,
    cancelledByUserId,
    cancelledAt,
  );
}

/// Contract for reception QR kiosk, client QR check-in, and visit logs.
abstract interface class ReceptionVisitsRepository {
  Future<GymQrToken> fetchGymQr({required int gymId});

  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  });

  Future<List<VisitRecord>> listCompanyVisits();

  Future<List<VisitRecord>> listClientVisits({required int clientId});

  Future<CheckInResult> registerManualVisit({
    required int clientId,
    required int gymId,
    DateTime? visitedAt,
    String? device,
    String? idempotencyKey,
  });

  Future<VisitRecord> cancelVisit({
    required int visitId,
    required String reason,
  });
}
