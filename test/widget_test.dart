import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';
import 'package:ugym_business/core/network/business_api_client.dart';
import 'package:ugym_business/core/router/business_shell.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/theme_controller.dart';
import 'package:ugym_business/main.dart';
import 'package:ugym_core/ugym_core.dart';

final class _HealthMockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        'app': 'ok',
        'database': 'ok',
        'redis': 'ok',
      }),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AppConfig', () {
    test('provides valid flavor presets', () {
      const dev = AppConfig.dev();
      const staging = AppConfig.staging();
      const prod = AppConfig.prod();

      expect(dev.flavor, AppFlavor.dev);
      expect(dev.apiBaseUrl, startsWith('http://'));
      expect(dev.enableKioskMode, isTrue);

      expect(staging.flavor, AppFlavor.staging);
      expect(staging.apiBaseUrl, startsWith('https://'));

      expect(prod.flavor, AppFlavor.prod);
      expect(prod.apiBaseUrl, startsWith('https://'));
    });
  });

  group('AppPreferences & ThemeController', () {
    test(
      'defaults to light theme and persists mode, locale, and gym',
      () async {
        final storage = InMemoryTokenStorage();
        final prefs = AppPreferences(storage: storage);

        expect(await prefs.readThemeMode(), ThemeMode.light);
        expect(await prefs.readLocaleCode(), 'ru');
        expect(await prefs.readSelectedGymId(), isNull);
        expect(await prefs.readSelectedGymTimezone(), 'Asia/Dushanbe');

        final controller = ThemeController(preferences: prefs);
        expect(controller.themeMode, ThemeMode.light);

        await controller.setThemeMode(ThemeMode.dark);
        expect(controller.themeMode, ThemeMode.dark);
        expect(await prefs.readThemeMode(), ThemeMode.dark);

        final reloaded = ThemeController(preferences: prefs);
        await reloaded.load();
        expect(reloaded.themeMode, ThemeMode.dark);

        await prefs.writeLocaleCode('tg');
        await prefs.writeSelectedGymId(42);
        await prefs.writeSelectedGymTimezone('Asia/Dushanbe');
        expect(await prefs.readLocaleCode(), 'tg');
        expect(await prefs.readSelectedGymId(), 42);
        expect(await prefs.readSelectedGymTimezone(), 'Asia/Dushanbe');

        await prefs.writeSelectedGymId(null);
        expect(await prefs.readSelectedGymId(), isNull);
      },
    );
  });

  group('BusinessApiClient', () {
    test('wires AppConfig baseUrl and TokenStorage into UgymHttpClient', () {
      final storage = InMemoryTokenStorage(initialToken: 'token-123');
      final client = BusinessApiClient(
        config: const AppConfig.staging(),
        tokenStorage: storage,
      );

      expect(
        client.httpClient.dio.options.baseUrl,
        'https://staging-api.ugym.tj/api/v1',
      );
    });
  });

  group('BusinessShell adaptive navigation, l10n, and health', () {
    test('filters navigation destinations by role', () {
      expect(
        BusinessShell.visibleDestinationsFor(BusinessRole.owner),
        hasLength(5),
      );
      expect(
        BusinessShell.visibleDestinationsFor(BusinessRole.admin),
        isNot(contains(BusinessDestination.analytics)),
      );
      expect(BusinessShell.visibleDestinationsFor(BusinessRole.trainer), const [
        BusinessDestination.operations,
        BusinessDestination.more,
      ]);
    });

    testWidgets('switches ru/tg/en on the fly and checks /health', (
      tester,
    ) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final themeController = ThemeController(preferences: prefs);
      final localeController = LocaleController(preferences: prefs);
      final sessionController = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
      );
      final apiClient = BusinessApiClient(
        config: const AppConfig.dev(),
        tokenStorage: InMemoryTokenStorage(),
      );
      apiClient.httpClient.dio.httpClientAdapter = _HealthMockAdapter();
      final healthService = UgymHealthService(httpClient: apiClient.httpClient);

      addTearDown(themeController.dispose);
      addTearDown(localeController.dispose);
      addTearDown(sessionController.dispose);

      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UgymBusinessApp(
          themeController: themeController,
          localeController: localeController,
          sessionController: sessionController,
          healthService: healthService,
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Аналитика'), findsOneWidget);

      await tester.tap(find.text('TG'));
      await tester.pumpAndSettle();
      expect(localeController.localeCode, 'tg');
      expect(await prefs.readLocaleCode(), 'tg');
      expect(find.text('Таҳлил'), findsOneWidget);

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('Analytics'), findsOneWidget);

      await tester.tap(find.text('Check health'));
      await tester.pumpAndSettle();
      expect(find.text('Server and databases are healthy'), findsOneWidget);

      await tester.tap(find.text('Dark theme'));
      await tester.pumpAndSettle();
      expect(themeController.themeMode, ThemeMode.dark);
    });

    testWidgets('uses NavigationRail on tablet width >= 600dp', (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final sessionController = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.admin,
      );
      addTearDown(sessionController.dispose);

      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UgymBusinessApp(sessionController: sessionController),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Аналитика'), findsNothing);
    });
  });
}
