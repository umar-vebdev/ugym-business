import 'package:material_ui/material_ui.dart';

import '../storage/app_preferences.dart';

/// Supported interface locales matching uCraft Design System 1.0 (`ru`, `tg`, `en`).
enum AppLocale {
  ru('ru', 'RU'),
  tg('tg', 'TG'),
  en('en', 'EN');

  const AppLocale(this.code, this.shortLabel);

  final String code;
  final String shortLabel;

  static AppLocale fromCode(String? code) {
    return switch (code) {
      'tg' => AppLocale.tg,
      'en' => AppLocale.en,
      _ => AppLocale.ru,
    };
  }
}

/// Strongly-typed UI strings synchronized with `lib/l10n/app_*.arb`.
@immutable
final class BusinessStrings {
  const BusinessStrings._({
    required this.appTitle,
    required this.navOverview,
    required this.navMembers,
    required this.navOperations,
    required this.navAnalytics,
    required this.navMore,
    required this.readOnlyBanner,
    required this.healthOk,
    required this.healthError,
    required this.checkHealth,
    required this.switchTheme,
    required this.selectBranch,
    required this.themeLightLabel,
    required this.themeDarkLabel,
  });

  final String appTitle;
  final String navOverview;
  final String navMembers;
  final String navOperations;
  final String navAnalytics;
  final String navMore;
  final String readOnlyBanner;
  final String healthOk;
  final String healthError;
  final String checkHealth;
  final String switchTheme;
  final String selectBranch;
  final String themeLightLabel;
  final String themeDarkLabel;

  static const BusinessStrings ru = BusinessStrings._(
    appTitle: 'uGym Business',
    navOverview: 'Обзор',
    navMembers: 'Клиенты',
    navOperations: 'Операции',
    navAnalytics: 'Аналитика',
    navMore: 'Ещё',
    readOnlyBanner: 'Подписка истекла — доступен только просмотр',
    healthOk: 'Сервер и базы доступны',
    healthError: 'Сервер недоступен',
    checkHealth: 'Проверить связь',
    switchTheme: 'Сменить тему',
    selectBranch: 'Выбор филиала',
    themeLightLabel: 'Светлая тема',
    themeDarkLabel: 'Тёмная тема',
  );

  static const BusinessStrings tg = BusinessStrings._(
    appTitle: 'uGym Business',
    navOverview: 'Шарҳ',
    navMembers: 'Мизоҷон',
    navOperations: 'Амалиёт',
    navAnalytics: 'Таҳлил',
    navMore: 'Бештар',
    readOnlyBanner: 'Обуна ба охир расид — танҳо дидан дастрас аст',
    healthOk: 'Сервер ва пойгоҳҳо дастрасанд',
    healthError: 'Сервер дастнорас аст',
    checkHealth: 'Санҷиши пайваст',
    switchTheme: 'Иваз кардани мавзӯъ',
    selectBranch: 'Интихоби филиал',
    themeLightLabel: 'Мавзӯи равшан',
    themeDarkLabel: 'Мавзӯи торик',
  );

  static const BusinessStrings en = BusinessStrings._(
    appTitle: 'uGym Business',
    navOverview: 'Overview',
    navMembers: 'Members',
    navOperations: 'Operations',
    navAnalytics: 'Analytics',
    navMore: 'More',
    readOnlyBanner: 'Subscription expired — read-only mode',
    healthOk: 'Server and databases are healthy',
    healthError: 'Server unavailable',
    checkHealth: 'Check health',
    switchTheme: 'Switch theme',
    selectBranch: 'Select branch',
    themeLightLabel: 'Light theme',
    themeDarkLabel: 'Dark theme',
  );

  static BusinessStrings of(AppLocale locale) {
    return switch (locale) {
      AppLocale.ru => ru,
      AppLocale.tg => tg,
      AppLocale.en => en,
    };
  }
}

/// Persists and broadcasts active application language changes.
final class LocaleController extends ChangeNotifier {
  LocaleController({
    required this.preferences,
    AppLocale initialLocale = AppLocale.ru,
  }) : _locale = initialLocale;

  final AppPreferences preferences;
  AppLocale _locale;

  AppLocale get locale => _locale;
  String get localeCode => _locale.code;
  BusinessStrings get strings => BusinessStrings.of(_locale);

  Future<void> load() async {
    final stored = await preferences.readLocaleCode();
    final parsed = AppLocale.fromCode(stored);
    if (parsed != _locale) {
      _locale = parsed;
      notifyListeners();
    }
  }

  Future<void> setLocale(AppLocale newLocale) async {
    if (newLocale == _locale) {
      return;
    }
    _locale = newLocale;
    notifyListeners();
    await preferences.writeLocaleCode(newLocale.code);
  }
}

