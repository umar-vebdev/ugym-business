import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';
import 'package:ugym_business/core/router/business_shell.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/theme_controller.dart';
import 'package:ugym_core/ugym_core.dart';

void main() {
  test('Inter and GeistMono OFL font files are bundled and registered in pubspec.yaml', () {
    expect(File('assets/fonts/Inter-Variable.ttf').existsSync(), isTrue);
    expect(File('assets/fonts/Inter-OFL.txt').existsSync(), isTrue);
    expect(File('assets/fonts/GeistMono-Variable.ttf').existsSync(), isTrue);
    expect(File('assets/fonts/GeistMono-OFL.txt').existsSync(), isTrue);

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: ${UcraftTypography.primaryFontFamily}'));
    expect(pubspec, contains('assets/fonts/Inter-Variable.ttf'));
    expect(pubspec, contains('family: ${UcraftTypography.monoFontFamily}'));
    expect(pubspec, contains('assets/fonts/GeistMono-Variable.ttf'));
  });

  testWidgets('BusinessShell and core guards render Lucide icons', (
    tester,
  ) async {
    final prefs = AppPreferences(storage: InMemoryTokenStorage());
    final session = BusinessSessionController(
      preferences: prefs,
      initialRole: BusinessRole.owner,
      initialReadOnly: true,
    );
    final locale = LocaleController(preferences: prefs);
    final theme = ThemeController(preferences: prefs);
    await session.setGyms(const [
      GymSummary(id: 1, name: 'Центр'),
      GymSummary(id: 2, name: 'Сино'),
    ]);
    addTearDown(session.dispose);
    addTearDown(locale.dispose);
    addTearDown(theme.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: UcraftTheme.light(),
        home: BusinessShell(
          config: const AppConfig.dev(),
          sessionController: session,
          localeController: locale,
          themeController: theme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.layoutDashboard), findsOneWidget);
    expect(find.byIcon(LucideIcons.users), findsOneWidget);
    expect(find.byIcon(LucideIcons.qrCode), findsOneWidget);
    expect(find.byIcon(LucideIcons.chartColumn), findsOneWidget);
    expect(find.byIcon(LucideIcons.menu), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    expect(find.byIcon(LucideIcons.dumbbell), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
  });

  test('Application code in lib/ uses Lucide icons exclusively (no Material Icons.*)', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final materialIconPattern = RegExp(r'\bIcons\.');

    final violations = <String>[];
    for (final file in dartFiles) {
      if (materialIconPattern.hasMatch(file.readAsStringSync())) {
        violations.add(file.path);
      }
    }

    expect(violations, isEmpty);
  });
}
