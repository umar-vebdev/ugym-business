import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/main.dart';

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

  group('UgymBusinessApp', () {
    testWidgets('renders initial business shell', (tester) async {
      await tester.pumpWidget(const UgymBusinessApp());
      expect(find.text('uGym Business (dev)'), findsOneWidget);
    });
  });
}
