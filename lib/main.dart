import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import 'core/config/app_config.dart';
import 'core/l10n/business_localizations.dart';
import 'core/network/business_api_client.dart';
import 'core/router/business_shell.dart';
import 'core/session/business_session_controller.dart';
import 'core/storage/app_preferences.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/remote_auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_flow_screen.dart';
import 'features/company_onboarding/data/remote_company_onboarding_repository.dart';
import 'features/company_onboarding/domain/company_onboarding_models.dart';
import 'features/reception_qr/data/remote_reception_visits_repository.dart';
import 'features/reception_qr/domain/kiosk_security.dart';
import 'features/reception_qr/domain/reception_visits_models.dart';

void main() {
  const config = AppConfig.dev();
  const storage = SecureTokenStorage();
  const preferences = AppPreferences(storage: storage);

  final themeController = ThemeController(preferences: preferences);
  final localeController = LocaleController(preferences: preferences);
  final sessionController = BusinessSessionController(preferences: preferences);

  late final AuthController authController;

  final apiClient = BusinessApiClient(
    config: config,
    tokenStorage: storage,
    localeProvider: () => localeController.localeCode,
    onUnauthorized: () => unawaited(authController.logout()),
    onSubscriptionExpired: sessionController.markSubscriptionExpired,
  );
  final healthService = UgymHealthService(httpClient: apiClient.httpClient);
  final authRepository = RemoteAuthRepository(
    httpClient: apiClient.httpClient,
    tokenStorage: storage,
  );
  final onboardingRepository = RemoteCompanyOnboardingRepository(
    httpClient: apiClient.httpClient,
  );
  final visitsRepository = RemoteReceptionVisitsRepository(
    httpClient: apiClient.httpClient,
  );
  const kioskPinGuard = KioskPinGuard(storage: storage);

  authController = AuthController(
    repository: authRepository,
    onAuthenticated: () async {
      await sessionController.bootstrapFromApi(apiClient.httpClient);
    },
    onSignedOut: () {
      sessionController.setRole(null);
      sessionController.setSubscriptionStatus(isReadOnly: false);
    },
  );

  unawaited(themeController.load());
  unawaited(localeController.load());
  unawaited(authController.tryRestoreSession(storage));

  runApp(
    UgymBusinessApp(
      config: config,
      themeController: themeController,
      localeController: localeController,
      sessionController: sessionController,
      authController: authController,
      healthService: healthService,
      onboardingRepository: onboardingRepository,
      visitsRepository: visitsRepository,
      kioskPinGuard: kioskPinGuard,
    ),
  );
}

/// Root widget of the uGym Business mobile application.
final class UgymBusinessApp extends StatefulWidget {
  const UgymBusinessApp({
    super.key,
    this.config = const AppConfig.dev(),
    this.themeController,
    this.localeController,
    this.sessionController,
    this.authController,
    this.healthService,
    this.onboardingRepository,
    this.visitsRepository,
    this.kioskPinGuard,
  });

  final AppConfig config;
  final ThemeController? themeController;
  final LocaleController? localeController;
  final BusinessSessionController? sessionController;
  final AuthController? authController;
  final UgymHealthService? healthService;
  final CompanyOnboardingRepository? onboardingRepository;
  final ReceptionVisitsRepository? visitsRepository;
  final KioskPinGuard? kioskPinGuard;

  @override
  State<UgymBusinessApp> createState() => _UgymBusinessAppState();
}

final class _UgymBusinessAppState extends State<UgymBusinessApp> {
  late final AppPreferences _fallbackPreferences;
  late final ThemeController _effectiveThemeController;
  late final LocaleController _effectiveLocaleController;
  late final BusinessSessionController _effectiveSessionController;
  late final bool _ownsTheme;
  late final bool _ownsLocale;
  late final bool _ownsSession;

  @override
  void initState() {
    super.initState();
    _fallbackPreferences = AppPreferences(storage: InMemoryTokenStorage());
    _ownsTheme = widget.themeController == null;
    _ownsLocale = widget.localeController == null;
    _ownsSession = widget.sessionController == null;

    _effectiveThemeController =
        widget.themeController ??
        ThemeController(preferences: _fallbackPreferences);
    _effectiveLocaleController =
        widget.localeController ??
        LocaleController(preferences: _fallbackPreferences);
    _effectiveSessionController =
        widget.sessionController ??
        BusinessSessionController(preferences: _fallbackPreferences);
  }

  @override
  void dispose() {
    if (_ownsTheme) {
      _effectiveThemeController.dispose();
    }
    if (_ownsLocale) {
      _effectiveLocaleController.dispose();
    }
    if (_ownsSession) {
      _effectiveSessionController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listened = Listenable.merge([
      _effectiveThemeController,
      _effectiveLocaleController,
      if (widget.authController != null) widget.authController,
    ]);

    return ListenableBuilder(
      listenable: listened,
      builder: (context, _) {
        final bool requiresAuth =
            widget.authController != null &&
            !widget.authController!.isAuthenticated;

        return MaterialApp(
          title: 'uGym Business',
          debugShowCheckedModeBanner: false,
          theme: UcraftTheme.light(),
          darkTheme: UcraftTheme.dark(),
          themeMode: _effectiveThemeController.themeMode,
          home: requiresAuth
              ? AuthFlowScreen(controller: widget.authController!)
              : BusinessShell(
                  config: widget.config,
                  sessionController: _effectiveSessionController,
                  localeController: _effectiveLocaleController,
                  themeController: _effectiveThemeController,
                  authController: widget.authController,
                  healthService: widget.healthService,
                  onboardingRepository: widget.onboardingRepository,
                  visitsRepository: widget.visitsRepository,
                  kioskPinGuard: widget.kioskPinGuard,
                ),
        );
      },
    );
  }
}
