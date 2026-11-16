import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import 'core/config/app_config.dart';
import 'core/storage/app_preferences.dart';
import 'core/theme/theme_controller.dart';

void main() {
  const storage = SecureTokenStorage();
  const preferences = AppPreferences(storage: storage);
  final themeController = ThemeController(preferences: preferences);
  unawaited(themeController.load());

  runApp(UgymBusinessApp(themeController: themeController));
}

/// Root widget of the uGym Business mobile application.
final class UgymBusinessApp extends StatefulWidget {
  const UgymBusinessApp({
    super.key,
    this.config = const AppConfig.dev(),
    this.themeController,
  });

  final AppConfig config;
  final ThemeController? themeController;

  @override
  State<UgymBusinessApp> createState() => _UgymBusinessAppState();
}

final class _UgymBusinessAppState extends State<UgymBusinessApp> {
  late final ThemeController _effectiveThemeController;
  late final bool _ownsThemeController;

  @override
  void initState() {
    super.initState();
    _ownsThemeController = widget.themeController == null;
    _effectiveThemeController =
        widget.themeController ??
        ThemeController(
          preferences: AppPreferences(storage: InMemoryTokenStorage()),
        );
  }

  @override
  void dispose() {
    if (_ownsThemeController) {
      _effectiveThemeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _effectiveThemeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'uGym Business',
          debugShowCheckedModeBanner: false,
          theme: UcraftTheme.light(),
          darkTheme: UcraftTheme.dark(),
          themeMode: _effectiveThemeController.themeMode,
          home: _BootstrapScreen(
            config: widget.config,
            themeController: _effectiveThemeController,
          ),
        );
      },
    );
  }
}

final class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen({required this.config, required this.themeController});

  final AppConfig config;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: UcraftSpacing.screenHorizontalPadding,
          ),
          child: Center(
            child: UcraftCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'uGym Business',
                    style: UcraftTypography.headline.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: UcraftSpacing.space2),
                  Text(
                    config.flavor.name,
                    style: UcraftTypography.mono.copyWith(
                      color: colors.foregroundSecondary,
                    ),
                  ),
                  const SizedBox(height: UcraftSpacing.space4),
                  UcraftButton(
                    label: isDark ? 'Light theme' : 'Dark theme',
                    variant: UcraftButtonVariant.secondary,
                    onPressed: () {
                      unawaited(
                        themeController.setThemeMode(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
