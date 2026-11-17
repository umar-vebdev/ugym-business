/// Moderation lifecycle state of a gym storefront profile.
enum ModerationStatus {
  draft('draft'),
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const ModerationStatus(this.apiValue);

  final String apiValue;

  static ModerationStatus fromApi(String? raw) {
    return switch (raw) {
      'pending' => ModerationStatus.pending,
      'approved' => ModerationStatus.approved,
      'rejected' => ModerationStatus.rejected,
      _ => ModerationStatus.draft,
    };
  }
}

/// Company staff role returned by `/business/staff`.
enum StaffRoleValue {
  owner('owner'),
  admin('admin'),
  trainer('trainer');

  const StaffRoleValue(this.apiValue);

  final String apiValue;

  static StaffRoleValue fromApi(String? raw) {
    return switch (raw) {
      'owner' => StaffRoleValue.owner,
      'trainer' => StaffRoleValue.trainer,
      _ => StaffRoleValue.admin,
    };
  }
}

/// Public storefront profile of a gym branch.
final class GymProfile {
  const GymProfile({
    required this.gymId,
    required this.isPublic,
    required this.moderationStatus,
    this.rejectionReason,
    this.description,
    this.address,
    this.district,
    this.latitude,
    this.longitude,
    this.phone,
    this.workingHours,
    this.amenities = const <String>[],
  });

  final int gymId;
  final bool isPublic;
  final ModerationStatus moderationStatus;
  final String? rejectionReason;
  final String? description;
  final String? address;
  final String? district;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final Object? workingHours;
  final List<String> amenities;
}

/// Payload for replacing a gym storefront profile via `PUT`.
final class GymProfileInput {
  const GymProfileInput({
    this.description,
    this.address,
    this.district,
    this.latitude,
    this.longitude,
    this.phone,
    this.workingHours,
    this.amenities,
  });

  final String? description;
  final String? address;
  final String? district;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final Object? workingHours;
  final List<String>? amenities;
}

/// Uploaded gallery photo of a gym branch.
final class GymPhoto {
  const GymPhoto({
    required this.id,
    required this.gymId,
    required this.url,
    required this.order,
    required this.createdAt,
  });

  final int id;
  final int gymId;
  final String url;
  final int order;
  final DateTime createdAt;
}

/// Company staff member record.
final class StaffMember {
  const StaffMember({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.role,
    this.name,
    this.phone,
    this.email,
  });

  final int id;
  final int userId;
  final int companyId;
  final StaffRoleValue role;
  final String? name;
  final String? phone;
  final String? email;
}

/// Contract for gym storefront, photo gallery, and staff management.
abstract interface class StorefrontAndStaffRepository {
  Future<GymProfile> updateGymProfile({
    required int gymId,
    required GymProfileInput input,
  });

  Future<GymProfile> submitGymProfile({required int gymId});

  Future<GymProfile> setGymPublication({
    required int gymId,
    required bool isPublic,
  });

  Future<GymPhoto> uploadGymPhoto({
    required int gymId,
    required List<int> bytes,
    required String filename,
  });

  Future<void> deleteGymPhoto({required int gymId, required int photoId});

  Future<List<StaffMember>> listStaff();

  Future<StaffMember> inviteStaff({
    required String email,
    required StaffRoleValue role,
  });

  Future<StaffMember> updateStaffRole({
    required int staffId,
    required StaffRoleValue role,
  });

  Future<void> deleteStaff({required int staffId});
}
