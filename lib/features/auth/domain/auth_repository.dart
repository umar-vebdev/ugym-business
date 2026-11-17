import 'authenticated_user.dart';

/// Contract for staff/owner authentication, Email OTP, and password reset.
abstract interface class AuthRepository {
  Future<String> login({
    String? email,
    String? phone,
    required String password,
    String device = 'mobile',
  });

  Future<int> registerUser({
    String? email,
    String? phone,
    required String password,
  });

  Future<String> sendEmailOtp({required String email});

  Future<String> verifyEmailOtp({required String email, required String code});

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> logout();

  Future<AuthenticatedUser> getCurrentUser();
}
