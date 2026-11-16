import 'package:material_ui/material_ui.dart';

import '../storage/app_preferences.dart';

/// Manages Light / Dark / System theme mode with persistence.
final class ThemeController extends ChangeNotifier {
  ThemeController({
    required this.preferences,
    ThemeMode initialMode = ThemeMode.light,
  }) : _themeMode = initialMode;

  final AppPreferences preferences;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final storedMode = await preferences.readThemeMode();
    if (storedMode != _themeMode) {
      _themeMode = storedMode;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await preferences.writeThemeMode(mode);
  }
}
