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

void main() {
  const config = AppConfig.dev();
  const storage = SecureTokenStorage();
  const preferences = AppPreferences(storage: storage);

  final themeController = ThemeController(preferences: preferences);
  final localeController = LocaleController(preferences: preferences);
  final sessionController = BusinessSessionController(preferences: preferences);

  final apiClient = BusinessApiClient(
    config: config,
    tokenStorage: storage,
    localeProvider: () => localeController.localeCode,
    onSubscriptionExpired: sessionController.markSubscriptionExpired,
  );
  final healthService = UgymHealthService(httpClient: apiClient.httpClient);

  unawaited(themeController.load());
  unawaited(localeController.load());

  runApp(
    UgymBusinessApp(
      config: config,
      themeController: themeController,
      localeController: localeController,
      sessionController: sessionController,
      healthService: healthService,
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
    this.healthService,
  });

  final AppConfig config;
  final ThemeController? themeController;
  final LocaleController? localeController;
  final BusinessSessionController? sessionController;
  final UgymHealthService? healthService;

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
    ]);

    return ListenableBuilder(
      listenable: listened,
      builder: (context, _) {
        return MaterialApp(
          title: 'uGym Business',
          debugShowCheckedModeBanner: false,
          theme: UcraftTheme.light(),
          darkTheme: UcraftTheme.dark(),
          themeMode: _effectiveThemeController.themeMode,
          home: BusinessShell(
            config: widget.config,
            sessionController: _effectiveSessionController,
            localeController: _effectiveLocaleController,
            themeController: _effectiveThemeController,
            healthService: widget.healthService,
          ),
        );
      },
    );
  }
}
