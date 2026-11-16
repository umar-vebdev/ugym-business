import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

/// Persists theme preference, locale, and currently selected gym context.
final class AppPreferences {
  const AppPreferences({required this.storage});

  static const String _themeModeKey = 'ugym_business_theme_mode';
  static const String _localeCodeKey = 'ugym_business_locale';
  static const String _selectedGymIdKey = 'ugym_business_selected_gym_id';
  static const String _selectedGymTimezoneKey = 'ugym_business_selected_gym_tz';

  static const String defaultLocaleCode = 'ru';
  static const String defaultTimezone = 'Asia/Dushanbe';

  final TokenStorage storage;

  Future<ThemeMode> readThemeMode() async {
    final raw = await storage.read(_themeModeKey);
    return switch (raw) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  Future<void> writeThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    return storage.write(_themeModeKey, value);
  }

  Future<String> readLocaleCode() async {
    final raw = await storage.read(_localeCodeKey);
    if (raw == 'ru' || raw == 'tg' || raw == 'en') {
      return raw!;
    }
    return defaultLocaleCode;
  }

  Future<void> writeLocaleCode(String code) {
    return storage.write(_localeCodeKey, code);
  }

  Future<int?> readSelectedGymId() async {
    final raw = await storage.read(_selectedGymIdKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  Future<void> writeSelectedGymId(int? gymId) {
    if (gymId == null) {
      return storage.delete(_selectedGymIdKey);
    }
    return storage.write(_selectedGymIdKey, gymId.toString());
  }

  Future<String> readSelectedGymTimezone() async {
    final raw = await storage.read(_selectedGymTimezoneKey);
    if (raw == null || raw.trim().isEmpty) {
      return defaultTimezone;
    }
    return raw;
  }

  Future<void> writeSelectedGymTimezone(String timezone) {
    return storage.write(_selectedGymTimezoneKey, timezone);
  }
}
