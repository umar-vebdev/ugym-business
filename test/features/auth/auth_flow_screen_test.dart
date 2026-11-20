import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/router/business_shell.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/business_theme.dart';
import 'package:ugym_business/features/auth/domain/auth_repository.dart';
import 'package:ugym_business/features/auth/domain/authenticated_user.dart';
import 'package:ugym_business/features/auth/presentation/auth_controller.dart';
import 'package:ugym_business/features/auth/presentation/auth_flow_screen.dart';
import 'package:ugym_business/main.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeAuthRepository implements AuthRepository {
  String? lastLoginEmail;
  String? lastLoginPhone;
  bool shouldFailLogin = false;
  bool logoutCalled = false;
  String? verifiedCode;
  String? resetCode;

  @override
  Future<String> login({
    String? email,
    String? phone,
    required String password,
    String device = 'mobile',
  }) async {
    if (shouldFailLogin) {
      throw const UgymApiException(
        statusCode: 422,
        code: 'VALIDATION_FAILED',
        message: 'Invalid credentials.',
        fieldErrors: <String, List<String>>{
          'email': <String>['Неверный email или пароль'],
        },
      );
    }
    lastLoginEmail = email;
    lastLoginPhone = phone;
    return 'tok-fake';
  }

  @override
  Future<int> registerUser({
    String? email,
    String? phone,
    required String password,
  }) async => 15;

  @override
  Future<String> sendEmailOtp({required String email}) async =>
      'Код отправлен на $email';

  @override
  Future<String> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    verifiedCode = code;
    return 'Email подтверждён';
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    resetCode = code;
    return 'Пароль обновлён';
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<AuthenticatedUser> getCurrentUser() async {
    return AuthenticatedUser(
      id: 15,
      name: 'Owner',
      email: 'owner@gym.tj',
      emailVerifiedAt: DateTime.utc(2026, 11, 17),
    );
  }
}

void main() {
  group('AuthFlowScreen & AuthController', () {
    testWidgets('logs in via email, opens BusinessShell, and signs out', (
      tester,
    ) async {
      final repo = _FakeAuthRepository();
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(preferences: prefs);
      final authController = AuthController(
        repository: repo,
        onAuthenticated: () async {
          session.setRole(BusinessRole.owner);
        },
        onSignedOut: () {
          session.setRole(null);
        },
      );

      addTearDown(session.dispose);
      addTearDown(authController.dispose);

      await tester.pumpWidget(
        UgymBusinessApp(
          sessionController: session,
          authController: authController,
        ),
      );

      expect(find.byType(AuthFlowScreen), findsOneWidget);
      expect(find.byType(BusinessShell), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey<String>('login_identifier')),
        'owner@gym.tj',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('login_password')),
        'password123',
      );
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      expect(repo.lastLoginEmail, 'owner@gym.tj');
      expect(repo.lastLoginPhone, isNull);
      expect(authController.isAuthenticated, isTrue);
      expect(find.byType(BusinessShell), findsOneWidget);

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Выйти'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();

      expect(repo.logoutCalled, isTrue);
      expect(authController.isAuthenticated, isFalse);
      expect(find.byType(AuthFlowScreen), findsOneWidget);
    });

    testWidgets('shows validation errors in light and dark themes', (
      tester,
    ) async {
      final repo = _FakeAuthRepository()..shouldFailLogin = true;

      for (final theme in [BusinessTheme.light, BusinessTheme.dark]) {
        final authController = AuthController(repository: repo);
        addTearDown(authController.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: AuthFlowScreen(controller: authController),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SvgPicture), findsOneWidget);
        final identifier = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        final border = identifier.decoration?.enabledBorder;
        expect(
          border?.borderSide.color,
          theme.extension<UcraftColors>()!.borderStrong,
        );

        await tester.enterText(
          find.byKey(const ValueKey<String>('login_identifier')),
          '+992900001122',
        );
        await tester.enterText(
          find.byKey(const ValueKey<String>('login_password')),
          'wrong',
        );
        await tester.tap(find.text('Войти'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid credentials.'), findsOneWidget);
        expect(find.text('Неверный email или пароль'), findsOneWidget);
      }
    });

    testWidgets('completes registration -> Email OTP and password reset', (
      tester,
    ) async {
      final repo = _FakeAuthRepository();
      final authController = AuthController(repository: repo);
      addTearDown(authController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: AuthFlowScreen(controller: authController),
        ),
      );

      await tester.tap(find.text('Создать аккаунт'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('register_email')),
        'new@gym.tj',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('register_password')),
        'password123',
      );
      await tester.tap(find.text('Зарегистрироваться'));
      await tester.pumpAndSettle();

      expect(authController.step, AuthStep.verifyOtp);
      expect(find.text('Код отправлен на new@gym.tj'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('otp_code')),
        '654321',
      );
      await tester.tap(find.text('Подтвердить email'));
      await tester.pumpAndSettle();

      expect(repo.verifiedCode, '654321');
      expect(authController.step, AuthStep.login);
      expect(find.text('Email подтверждён'), findsOneWidget);

      await tester.tap(find.text('Сбросить пароль'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('reset_email')),
        'new@gym.tj',
      );
      await tester.tap(find.text('Получить код на email'));
      await tester.pumpAndSettle();
      expect(find.text('Код отправлен на new@gym.tj'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('reset_code')),
        '112233',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('reset_password')),
        'newpass123',
      );
      final savePassword = find.text('Сохранить новый пароль');
      await tester.ensureVisible(savePassword);
      await tester.tap(savePassword);
      await tester.pumpAndSettle();

      expect(repo.resetCode, '112233');
      expect(authController.step, AuthStep.login);
      expect(find.text('Пароль обновлён'), findsOneWidget);
    });
  });
}
