import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';
import 'package:ugym_business/core/router/business_shell.dart';
import 'package:ugym_business/core/router/role_guard_and_banners.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/theme_controller.dart';
import 'package:ugym_business/features/auth/domain/auth_repository.dart';
import 'package:ugym_business/features/auth/domain/authenticated_user.dart';
import 'package:ugym_business/features/auth/presentation/auth_controller.dart';
import 'package:ugym_business/features/reception_qr/domain/kiosk_security.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/features/reception_qr/presentation/gym_qr_kiosk_screen.dart';
import 'package:ugym_business/main.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeAuthRepo implements AuthRepository {
  @override
  Future<AuthenticatedUser> getCurrentUser() => throw UnimplementedError();

  @override
  Future<String> login({
    String? email,
    String? phone,
    required String password,
    String device = 'mobile',
  }) => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<int> registerUser({
    String? email,
    String? phone,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => throw UnimplementedError();

  @override
  Future<String> sendEmailOtp({required String email}) =>
      throw UnimplementedError();

  @override
  Future<String> verifyEmailOtp({
    required String email,
    required String code,
  }) => throw UnimplementedError();
}

final class _FakeQrRepo implements ReceptionVisitsRepository {
  @override
  Future<GymQrToken> fetchGymQr({required int gymId}) async => GymQrToken(
    gymId: gymId,
    gymName: 'Atlas Central Flagship',
    slot: 101,
    token: 'gym|$gymId|101|hmac',
    ttlSeconds: 60,
    expiresAt: DateTime.utc(2026, 11, 18, 12, 1),
  );

  @override
  Future<VisitRecord> cancelVisit({
    required int visitId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<List<VisitRecord>> listClientVisits({required int clientId}) =>
      throw UnimplementedError();

  @override
  Future<List<VisitRecord>> listCompanyVisits() => throw UnimplementedError();

  @override
  Future<CheckInResult> registerManualVisit({
    required int clientId,
    required int gymId,
    DateTime? visitedAt,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'BusinessShell adapts across Compact (<600), Medium (600-839), and Expanded (>=840) breakpoints',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
      );
      final locale = LocaleController(preferences: prefs);
      final theme = ThemeController(preferences: prefs);
      addTearDown(session.dispose);
      addTearDown(locale.dispose);
      addTearDown(theme.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Widget buildShell() => MaterialApp(
        theme: UcraftTheme.light(),
        home: BusinessShell(
          config: const AppConfig.dev(),
          sessionController: session,
          localeController: locale,
          themeController: theme,
        ),
      );

      // Compact: 390x844 -> NavigationBar.
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildShell());
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Medium: 700x900 -> collapsed NavigationRail with labels.
      await tester.binding.setSurfaceSize(const Size(700, 900));
      await tester.pumpWidget(buildShell());
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      final mediumRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(mediumRail.extended, isFalse);
      expect(mediumRail.labelType, NavigationRailLabelType.all);

      // Expanded: 1024x768 -> extended NavigationRail + maxWidth 1040 content constraint.
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(buildShell());
      await tester.pumpAndSettle();
      final expandedRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(expandedRail.extended, isTrue);
      expect(expandedRail.labelType, NavigationRailLabelType.none);
      final hasMaxWidth1040 = tester
          .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
          .any((box) => box.constraints.maxWidth == 1040);
      expect(hasMaxWidth1040, isTrue);
    },
  );

  testWidgets(
    'GymQrKioskScreen renders two-column layout on iPad 1024x768 in Light/Dark with 1.25x text scale without overflow',
    (tester) async {
      final repo = _FakeQrRepo();
      final pinGuard = KioskPinGuard(storage: InMemoryTokenStorage());
      final fakeNow = DateTime.utc(2026, 11, 18, 12, 0);
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final theme in [UcraftTheme.light(), UcraftTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
              child: GymQrKioskScreen(
                gymId: 1,
                repository: repo,
                pinGuard: pinGuard,
                clock: () => fakeNow,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final qrCenter = tester.getCenter(find.byType(QrImageView));
        final pinCenter = tester.getCenter(
          find.text('Заблокировать киоск PIN-кодом'),
        );
        expect(qrCenter.dx, lessThan(pinCenter.dx));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  test(
    'ARB localization files (ru, tg, en) share the exact same set of keys',
    () {
      Set<String> keysOf(String path) {
        final decoded = jsonDecode(File(path).readAsStringSync());
        final map = decoded as Map<String, Object?>;
        return map.keys.where((k) => !k.startsWith('@@')).toSet();
      }

      final ruKeys = keysOf('lib/l10n/app_ru.arb');
      final tgKeys = keysOf('lib/l10n/app_tg.arb');
      final enKeys = keysOf('lib/l10n/app_en.arb');

      expect(ruKeys, isNotEmpty);
      expect(tgKeys, ruKeys);
      expect(enKeys, ruKeys);
    },
  );

  testWidgets(
    'UgymBusinessApp translates read-only banner, theme label, and sign-out across ru, tg, and en',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
        initialReadOnly: true,
      );
      final locale = LocaleController(preferences: prefs);
      final theme = ThemeController(preferences: prefs);
      final auth = AuthController(
        repository: _FakeAuthRepo(),
        initiallyAuthenticated: true,
      );
      addTearDown(session.dispose);
      addTearDown(locale.dispose);
      addTearDown(theme.dispose);
      addTearDown(auth.dispose);

      await tester.pumpWidget(
        UgymBusinessApp(
          sessionController: session,
          localeController: locale,
          themeController: theme,
          authController: auth,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();
      expect(find.text(BusinessStrings.ru.readOnlyBanner), findsOneWidget);
      expect(find.text(BusinessStrings.ru.themeDarkLabel), findsOneWidget);
      expect(find.text(BusinessStrings.ru.signOutLabel), findsOneWidget);

      await tester.tap(find.text('TG'));
      await tester.pumpAndSettle();
      expect(find.text(BusinessStrings.tg.readOnlyBanner), findsOneWidget);
      expect(find.text(BusinessStrings.tg.themeDarkLabel), findsOneWidget);
      expect(find.text(BusinessStrings.tg.signOutLabel), findsOneWidget);
      expect(find.text(BusinessStrings.tg.navMore), findsWidgets);

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text(BusinessStrings.en.readOnlyBanner), findsOneWidget);
      expect(find.text(BusinessStrings.en.themeDarkLabel), findsOneWidget);
      expect(find.text(BusinessStrings.en.signOutLabel), findsOneWidget);
    },
  );

  testWidgets(
    'Loading, empty, error, and permission-denied states render cleanly in Light and Dark themes',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final adminSession = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.admin,
      );
      addTearDown(adminSession.dispose);

      var retried = false;

      for (final theme in [UcraftTheme.light(), UcraftTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const UcraftLoadingState(message: 'Загрузка...'),
                    const UcraftEmptyState(
                      title: 'Пусто',
                      description: 'Нет данных',
                    ),
                    UcraftErrorState(
                      title: 'Ошибка',
                      message: 'Сбой сети',
                      retryLabel: 'Повторить',
                      onRetry: () => retried = true,
                    ),
                    RoleGuard(
                      controller: adminSession,
                      permission: BusinessPermission.viewAnalytics,
                      child: const Text('Hidden'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Загрузка...'), findsOneWidget);
        expect(find.text('Пусто'), findsOneWidget);
        expect(find.text('Ошибка'), findsOneWidget);
        expect(
          find.text('Недостаточно прав для доступа к разделу'),
          findsOneWidget,
        );
        expect(find.text('Hidden'), findsNothing);
        expect(tester.takeException(), isNull);
      }

      await tester.tap(find.text('Повторить'));
      expect(retried, isTrue);
    },
  );
}
