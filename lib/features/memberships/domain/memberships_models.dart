/// Pricing/access model of a membership type.
enum MembershipKind {
  unlimitedTime('unlimited_time'),
  visitsPack('visits_pack'),
  mixed('mixed');

  const MembershipKind(this.apiValue);

  final String apiValue;

  static MembershipKind fromApi(String? raw) {
    return switch (raw) {
      'visits_pack' => MembershipKind.visitsPack,
      'mixed' => MembershipKind.mixed,
      _ => MembershipKind.unlimitedTime,
    };
  }
}

/// When the validity period starts counting down.
enum MembershipStartMode {
  onPurchase('on_purchase'),
  onFirstVisit('on_first_visit');

  const MembershipStartMode(this.apiValue);

  final String apiValue;

  static MembershipStartMode fromApi(String? raw) {
    return switch (raw) {
      'on_first_visit' => MembershipStartMode.onFirstVisit,
      _ => MembershipStartMode.onPurchase,
    };
  }
}

/// Lifecycle status of an issued client membership.
enum MembershipStatus {
  active('active'),
  frozen('frozen'),
  expired('expired'),
  cancelled('cancelled'),
  pendingActivation('pending_activation');

  const MembershipStatus(this.apiValue);

  final String apiValue;

  static MembershipStatus fromApi(String? raw) {
    return switch (raw) {
      'frozen' => MembershipStatus.frozen,
      'expired' => MembershipStatus.expired,
      'cancelled' => MembershipStatus.cancelled,
      'pending_activation' => MembershipStatus.pendingActivation,
      _ => MembershipStatus.active,
    };
  }
}

/// Membership tariff template configured by the gym owner.
final class MembershipType {
  const MembershipType({
    required this.id,
    required this.name,
    required this.kind,
    required this.startMode,
    required this.priceMinor,
    required this.currency,
    required this.dailyLimit,
    required this.isActive,
    this.visitsCount,
    this.durationDays,
    this.validityDays,
    this.timeFromMinute,
    this.timeToMinute,
    this.freezeMaxDays = 0,
    this.freezeMaxTimes = 0,
  });

  final int id;
  final String name;
  final MembershipKind kind;
  final MembershipStartMode startMode;
  final int priceMinor;
  final String currency;
  final int? visitsCount;
  final int? durationDays;
  final int? validityDays;
  final int dailyLimit;
  final int? timeFromMinute;
  final int? timeToMinute;
  final int freezeMaxDays;
  final int freezeMaxTimes;
  final bool isActive;
}

/// Input payload to create a new membership type.
final class CreateMembershipTypeInput {
  const CreateMembershipTypeInput({
    required this.name,
    required this.priceMinor,
    required this.kind,
    required this.startMode,
    this.currency,
    this.visitsCount,
    this.durationDays,
    this.validityDays,
    this.dailyLimit,
    this.timeFrom,
    this.timeTo,
    this.freezeMaxDays,
    this.freezeMaxTimes,
  });

  final String name;
  final int priceMinor;
  final String? currency;
  final MembershipKind kind;
  final MembershipStartMode startMode;
  final int? visitsCount;
  final int? durationDays;
  final int? validityDays;
  final int? dailyLimit;
  final String? timeFrom;
  final String? timeTo;
  final int? freezeMaxDays;
  final int? freezeMaxTimes;
}

/// Issued membership owned by a client.
final class ClientMembership {
  const ClientMembership({
    required this.id,
    required this.clientId,
    required this.typeId,
    required this.kind,
    required this.status,
    this.remainingVisits,
    this.startsAt,
    this.endsAt,
    this.freezeDaysUsed = 0,
    this.freezeTimesUsed = 0,
    this.frozenAt,
    this.cancellationReason,
  });

  final int id;
  final int clientId;
  final int typeId;
  final MembershipKind kind;
  final MembershipStatus status;
  final int? remainingVisits;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int freezeDaysUsed;
  final int freezeTimesUsed;
  final DateTime? frozenAt;
  final String? cancellationReason;
}

/// Updated freeze state returned after freeze/unfreeze calls.
final class MembershipFreezeState {
  const MembershipFreezeState({
    required this.id,
    required this.status,
    required this.freezeDaysUsed,
    required this.freezeTimesUsed,
    this.frozenAt,
    this.endsAt,
  });

  final int id;
  final MembershipStatus status;
  final int freezeDaysUsed;
  final int freezeTimesUsed;
  final DateTime? frozenAt;
  final DateTime? endsAt;
}

/// Contract for membership tariffs and issued client memberships.
abstract interface class MembershipsRepository {
  Future<List<MembershipType>> listMembershipTypes({bool? onlyActive});

  Future<int> createMembershipType(CreateMembershipTypeInput input);

  Future<bool> setMembershipTypeActive({
    required int typeId,
    required bool isActive,
  });

  Future<List<ClientMembership>> listClientMemberships({required int clientId});

  Future<List<ClientMembership>> listExpiringMemberships();

  Future<MembershipFreezeState> freezeMembership({required int membershipId});

  Future<MembershipFreezeState> unfreezeMembership({required int membershipId});

  Future<ClientMembership> cancelMembership({
    required int membershipId,
    required String reason,
  });
}
