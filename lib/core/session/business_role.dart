/// Staff roles supported by uGym Business.
enum BusinessRole { owner, admin, trainer, noCompany }

/// Granular capabilities aligned with the uGym Business RBAC matrix.
enum BusinessPermission {
  createCompany,
  viewGyms,
  manageGyms,
  changeCompanyCurrency,
  manageStaff,
  manageStorefront,
  manageReceptionQrAndVisits,
  manageClientsCrm,
  mergeDuplicateClients,
  viewExpiringAndFreezeMemberships,
  manageMembershipTypesAndCancel,
  manageMembershipRequestsAndSales,
  refundSalesAndManageProducts,
  viewTrainers,
  manageTrainers,
  manageSchedule,
  viewSessionBookings,
  viewAnalytics,
  sendAnnouncements,
  viewBilling,
}

extension BusinessRolePermissions on BusinessRole {
  /// Returns `true` when this role is permitted to access [permission].
  bool can(BusinessPermission permission) {
    return switch (this) {
      BusinessRole.owner => permission != BusinessPermission.createCompany,
      BusinessRole.admin => switch (permission) {
        BusinessPermission.viewGyms ||
        BusinessPermission.manageReceptionQrAndVisits ||
        BusinessPermission.manageClientsCrm ||
        BusinessPermission.viewExpiringAndFreezeMemberships ||
        BusinessPermission.manageMembershipRequestsAndSales ||
        BusinessPermission.viewTrainers ||
        BusinessPermission.manageSchedule ||
        BusinessPermission.viewSessionBookings ||
        BusinessPermission.sendAnnouncements ||
        BusinessPermission.viewBilling => true,
        _ => false,
      },
      BusinessRole.trainer =>
        permission == BusinessPermission.viewSessionBookings,
      BusinessRole.noCompany => permission == BusinessPermission.createCompany,
    };
  }
}

/// Minimal gym branch descriptor stored in active session state.
final class GymSummary {
  const GymSummary({
    required this.id,
    required this.name,
    this.timezone = 'Asia/Dushanbe',
    this.publicId,
  });

  final int id;
  final String name;
  final String timezone;
  final String? publicId;

  static GymSummary? tryFromJson(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }

    final rawId = raw['id'];
    final int? id = rawId is int
        ? rawId
        : (rawId is num ? rawId.toInt() : null);
    final rawName = raw['name'];
    if (id == null || rawName is! String || rawName.trim().isEmpty) {
      return null;
    }

    final rawTimezone = raw['timezone'];
    final String timezone =
        rawTimezone is String && rawTimezone.trim().isNotEmpty
        ? rawTimezone
        : 'Asia/Dushanbe';

    final rawPublicId = raw['public_id'];
    final String? publicId = rawPublicId is String && rawPublicId.isNotEmpty
        ? rawPublicId
        : null;

    return GymSummary(
      id: id,
      name: rawName,
      timezone: timezone,
      publicId: publicId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymSummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          timezone == other.timezone &&
          publicId == other.publicId;

  @override
  int get hashCode => Object.hash(id, name, timezone, publicId);
}
