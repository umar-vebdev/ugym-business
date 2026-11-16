import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/network/business_api_client.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/theme_controller.dart';
import 'package:ugym_business/main.dart';
import 'package:ugym_core/ugym_core.dart';

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

  group('UgymBusinessApp', () {
    testWidgets('renders uCraft light theme and toggles dark theme', (
      tester,
    ) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final themeController = ThemeController(preferences: prefs);
      addTearDown(themeController.dispose);

      await tester.pumpWidget(
        UgymBusinessApp(themeController: themeController),
      );

      expect(find.text('uGym Business'), findsOneWidget);
      expect(find.text('dev'), findsOneWidget);

      final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        lightScaffold.backgroundColor ?? UcraftColors.light.background,
        UcraftColors.light.background,
      );

      await tester.tap(find.byType(UcraftButton));
      await tester.pumpAndSettle();

      expect(themeController.themeMode, ThemeMode.dark);
      expect(find.text('Light theme'), findsOneWidget);
    });
  });
}
