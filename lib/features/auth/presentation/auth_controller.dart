import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../domain/auth_repository.dart';
import '../domain/authenticated_user.dart';

/// Active screen step inside [AuthFlowScreen].
enum AuthStep { login, register, verifyOtp, resetPassword }

/// Coordinates sign-in, registration, Email OTP verification, password reset, and sign-out.
final class AuthController extends ChangeNotifier {
  AuthController({
    required this.repository,
    this.onAuthenticated,
    this.onSignedOut,
    bool initiallyAuthenticated = false,
  }) : _isAuthenticated = initiallyAuthenticated;

  final AuthRepository repository;
  final Future<void> Function()? onAuthenticated;
  final VoidCallback? onSignedOut;

  bool _isAuthenticated;
  bool _isSubmitting = false;
  AuthStep _step = AuthStep.login;
  AuthenticatedUser? _currentUser;
  String? _pendingEmail;
  String? _errorMessage;
  String? _infoMessage;
  Map<String, List<String>> _fieldErrors = const <String, List<String>>{};

  bool get isAuthenticated => _isAuthenticated;
  bool get isSubmitting => _isSubmitting;
  AuthStep get step => _step;
  AuthenticatedUser? get currentUser => _currentUser;
  String? get pendingEmail => _pendingEmail;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  String? firstFieldError(List<String> keys) {
    for (final key in keys) {
      final list = _fieldErrors[key];
      if (list != null && list.isNotEmpty) {
        return list.first;
      }
    }
    return null;
  }

  void showStep(AuthStep nextStep, {String? email}) {
    _step = nextStep;
    if (email != null && email.trim().isNotEmpty) {
      _pendingEmail = email.trim();
    }
    _clearFeedback();
    notifyListeners();
  }

  Future<void> tryRestoreSession(TokenStorage storage) async {
    final token = await storage.readToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      _currentUser = await repository.getCurrentUser();
      await onAuthenticated?.call();
      _isAuthenticated = true;
      notifyListeners();
    } on UgymApiException catch (error) {
      if (error.isUnauthorized) {
        await storage.deleteToken();
      }
    } on Object {
      // Keep user on auth screen if network is unavailable on cold start.
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
    String device = 'mobile',
  }) async {
    if (_isSubmitting) {
      return false;
    }

    final trimmed = identifier.trim();
    final bool looksLikeEmail = trimmed.contains('@');

    _beginSubmit();
    try {
      await repository.login(
        email: looksLikeEmail ? trimmed : null,
        phone: looksLikeEmail ? null : trimmed,
        password: password,
        device: device,
      );

      try {
        _currentUser = await repository.getCurrentUser();
      } on UgymApiException {
        // User fetch failure should not block a freshly issued token unless 401.
      }

      await onAuthenticated?.call();
      _isAuthenticated = true;
      return true;
    } on UgymApiException catch (error) {
      _applyApiError(error);
      return false;
    } finally {
      _endSubmit();
    }
  }

  Future<bool> registerAndSendOtp({
    required String email,
    String? phone,
    required String password,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    final trimmedEmail = email.trim();
    final trimmedPhone = phone?.trim();

    _beginSubmit();
    try {
      await repository.registerUser(
        email: trimmedEmail,
        phone: trimmedPhone != null && trimmedPhone.isNotEmpty
            ? trimmedPhone
            : null,
        password: password,
      );
      final message = await repository.sendEmailOtp(email: trimmedEmail);
      _pendingEmail = trimmedEmail;
      _step = AuthStep.verifyOtp;
      _infoMessage = message;
      return true;
    } on UgymApiException catch (error) {
      _applyApiError(error);
      return false;
    } finally {
      _endSubmit();
    }
  }

  Future<bool> resendOtp({required String email}) async {
    if (_isSubmitting) {
      return false;
    }

    final trimmedEmail = email.trim();
    _beginSubmit();
    try {
      final message = await repository.sendEmailOtp(email: trimmedEmail);
      _pendingEmail = trimmedEmail;
      _infoMessage = message;
      return true;
    } on UgymApiException catch (error) {
      _applyApiError(error);
      return false;
    } finally {
      _endSubmit();
    }
  }

  Future<bool> verifyOtp({required String email, required String code}) async {
    if (_isSubmitting) {
      return false;
    }

    final trimmedEmail = email.trim();
    _beginSubmit();
    try {
      final message = await repository.verifyEmailOtp(
        email: trimmedEmail,
        code: code.trim(),
      );
      _pendingEmail = trimmedEmail;
      _step = AuthStep.login;
      _infoMessage = message;
      return true;
    } on UgymApiException catch (error) {
      _applyApiError(error);
      return false;
    } finally {
      _endSubmit();
    }
  }

  Future<bool> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    final trimmedEmail = email.trim();
    _beginSubmit();
    try {
      final message = await repository.resetPassword(
        email: trimmedEmail,
        code: code.trim(),
        newPassword: newPassword,
      );
      _pendingEmail = trimmedEmail;
      _step = AuthStep.login;
      _infoMessage = message;
      return true;
    } on UgymApiException catch (error) {
      _applyApiError(error);
      return false;
    } finally {
      _endSubmit();
    }
  }

  Future<void> logout() async {
    if (_isSubmitting) {
      return;
    }

    _beginSubmit();
    try {
      await repository.logout();
    } finally {
      _isAuthenticated = false;
      _currentUser = null;
      _step = AuthStep.login;
      _clearFeedback();
      _isSubmitting = false;
      onSignedOut?.call();
      notifyListeners();
    }
  }

  void _beginSubmit() {
    _isSubmitting = true;
    _clearFeedback();
    notifyListeners();
  }

  void _endSubmit() {
    _isSubmitting = false;
    notifyListeners();
  }

  void _clearFeedback() {
    _errorMessage = null;
    _infoMessage = null;
    _fieldErrors = const <String, List<String>>{};
  }

  void _applyApiError(UgymApiException error) {
    _errorMessage = error.message;
    _fieldErrors = error.fieldErrors;
  }
}
