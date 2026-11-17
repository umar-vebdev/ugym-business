/// Authenticated staff or owner profile returned by `GET /api/v1/user`.
final class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    this.name,
    this.email,
    this.emailVerifiedAt,
    this.phone,
    this.isPhoneVerified = false,
    this.isPlatformAdmin = false,
  });

  final int id;
  final String? name;
  final String? email;
  final DateTime? emailVerifiedAt;
  final String? phone;
  final bool isPhoneVerified;
  final bool isPlatformAdmin;

  bool get isEmailVerified => emailVerifiedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthenticatedUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          emailVerifiedAt == other.emailVerifiedAt &&
          phone == other.phone &&
          isPhoneVerified == other.isPhoneVerified &&
          isPlatformAdmin == other.isPlatformAdmin;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    emailVerifiedAt,
    phone,
    isPhoneVerified,
    isPlatformAdmin,
  );
}
