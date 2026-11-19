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
    required this.signOutLabel,
    required this.detailsLabel,
    required this.retryLabel,
    required this.refreshLabel,
    required this.branchNotSelected,
    required this.noCompanyTitle,
    required this.noCompanyDescription,
    required this.createCompanyCta,
    required this.openClientAppCta,
    required this.permissionDeniedTitle,
    required this.permissionDeniedDescription,
    required this.subTabClients,
    required this.subTabExpiring,
    required this.subTabTypes,
    required this.subTabVisits,
    required this.subTabRequests,
    required this.subTabSales,
    required this.subTabProducts,
    required this.subTabSchedule,
    required this.subTabTrainers,
    required this.subTabSettings,
    required this.subTabStorefront,
    required this.subTabStaff,
    required this.subTabAnnouncements,
    required this.subTabBilling,
    required this.receptionAndPosTitle,
    required this.scanClientQrButton,
    required this.kioskQrButton,
    required this.openPosButton,
    required this.quickActionsTitle,
    required this.roleLabel,
    required this.roleUnset,
    required this.branchLabel,
    required this.revenueTodayTitle,
    required this.visitsTodayTitle,
    required this.pendingRequestsTitle,
    required this.pendingRequestsEmpty,
    required this.pendingRequestsHint,
    required this.goToRequestsButton,
    required this.expiringSoonTitle,
    required this.expiringSoonEmpty,
    required this.expiringSoonHint,
    required this.goToExpiringButton,
    required this.openAnalyticsButton,
    required this.overviewErrorTitle,
    required this.receiptsCountLabel,
    required this.membershipsLabel,
    required this.manualVisitsLabel,
    required this.newClientsLabel,
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
  final String signOutLabel;
  final String detailsLabel;
  final String retryLabel;
  final String refreshLabel;
  final String branchNotSelected;
  final String noCompanyTitle;
  final String noCompanyDescription;
  final String createCompanyCta;
  final String openClientAppCta;
  final String permissionDeniedTitle;
  final String permissionDeniedDescription;
  final String subTabClients;
  final String subTabExpiring;
  final String subTabTypes;
  final String subTabVisits;
  final String subTabRequests;
  final String subTabSales;
  final String subTabProducts;
  final String subTabSchedule;
  final String subTabTrainers;
  final String subTabSettings;
  final String subTabStorefront;
  final String subTabStaff;
  final String subTabAnnouncements;
  final String subTabBilling;
  final String receptionAndPosTitle;
  final String scanClientQrButton;
  final String kioskQrButton;
  final String openPosButton;
  final String quickActionsTitle;
  final String roleLabel;
  final String roleUnset;
  final String branchLabel;
  final String revenueTodayTitle;
  final String visitsTodayTitle;
  final String pendingRequestsTitle;
  final String pendingRequestsEmpty;
  final String pendingRequestsHint;
  final String goToRequestsButton;
  final String expiringSoonTitle;
  final String expiringSoonEmpty;
  final String expiringSoonHint;
  final String goToExpiringButton;
  final String openAnalyticsButton;
  final String overviewErrorTitle;
  final String receiptsCountLabel;
  final String membershipsLabel;
  final String manualVisitsLabel;
  final String newClientsLabel;

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
    signOutLabel: 'Выйти',
    detailsLabel: 'Подробнее',
    retryLabel: 'Повторить',
    refreshLabel: 'Обновить',
    branchNotSelected: 'Филиал не выбран',
    noCompanyTitle: 'Вы не являетесь сотрудником зала',
    noCompanyDescription:
        'Создайте свою компанию или откройте клиентское приложение uGym.',
    createCompanyCta: 'Создать компанию (14 дней бесплатно)',
    openClientAppCta: 'Перейти в клиентское приложение uGym',
    permissionDeniedTitle: 'Недостаточно прав для доступа к разделу',
    permissionDeniedDescription:
        'Доступ ограничен вашей текущей ролью в компании.',
    subTabClients: 'Клиенты',
    subTabExpiring: 'Истекающие',
    subTabTypes: 'Тарифы',
    subTabVisits: 'Визиты',
    subTabRequests: 'Заявки',
    subTabSales: 'Продажи',
    subTabProducts: 'Товары',
    subTabSchedule: 'Расписание',
    subTabTrainers: 'Тренеры',
    subTabSettings: 'Настройки',
    subTabStorefront: 'Витрина',
    subTabStaff: 'Штат',
    subTabAnnouncements: 'Рассылки',
    subTabBilling: 'Подписка',
    receptionAndPosTitle: 'Ресепшен и касса',
    scanClientQrButton: 'Сканер QR клиента',
    kioskQrButton: 'Киоск QR зала',
    openPosButton: 'Открыть кассу',
    quickActionsTitle: 'Быстрые действия',
    roleLabel: 'Роль',
    roleUnset: 'не определена',
    branchLabel: 'Филиал',
    revenueTodayTitle: 'Выручка сегодня',
    visitsTodayTitle: 'Посещения сегодня',
    pendingRequestsTitle: 'Заявки в ожидании',
    pendingRequestsEmpty: 'Необработанных заявок из uGym нет',
    pendingRequestsHint: 'Ожидают подтверждения оплаты на кассе',
    goToRequestsButton: 'К заявкам',
    expiringSoonTitle: 'Истекают за 7 дней',
    expiringSoonEmpty: 'Истекающих абонементов нет',
    expiringSoonHint: 'Абонементы для напоминания о продлении',
    goToExpiringButton: 'К истекающим',
    openAnalyticsButton: 'Открыть аналитику',
    overviewErrorTitle: 'Ошибка загрузки сводки',
    receiptsCountLabel: 'Чеков',
    membershipsLabel: 'Абонементы',
    manualVisitsLabel: 'Ручные',
    newClientsLabel: 'Новых клиентов',
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
    signOutLabel: 'Баромадан',
    detailsLabel: 'Муфассал',
    retryLabel: 'Такрор кардан',
    refreshLabel: 'Навсозӣ',
    branchNotSelected: 'Филиал интихоб нашудааст',
    noCompanyTitle: 'Шумо корманди толор нестед',
    noCompanyDescription:
        'Ширкати худро созед ё барномаи мизоҷи uGym-ро кушоед.',
    createCompanyCta: 'Сохтани ширкат (14 рӯз ройгон)',
    openClientAppCta: 'Гузаштан ба барномаи мизоҷи uGym',
    permissionDeniedTitle: 'Барои дастрасӣ ба ин бахш ҳуқуқ кофӣ нест',
    permissionDeniedDescription:
        'Дастрасӣ бо нақши кунунии шумо дар ширкат маҳдуд аст.',
    subTabClients: 'Мизоҷон',
    subTabExpiring: 'Анҷомёбанда',
    subTabTypes: 'Тарифҳо',
    subTabVisits: 'Ташрифҳо',
    subTabRequests: 'Дархостҳо',
    subTabSales: 'Фурӯшҳо',
    subTabProducts: 'Молҳо',
    subTabSchedule: 'Ҷадвал',
    subTabTrainers: 'Мураббиён',
    subTabSettings: 'Танзимот',
    subTabStorefront: 'Витрина',
    subTabStaff: 'Кормандон',
    subTabAnnouncements: 'Паёмномаҳо',
    subTabBilling: 'Обуна',
    receptionAndPosTitle: 'Қабулгоҳ ва хазина',
    scanClientQrButton: 'Сканери QR мизоҷ',
    kioskQrButton: 'Киоски QR толор',
    openPosButton: 'Кушодани хазина',
    quickActionsTitle: 'Амалҳои зуд',
    roleLabel: 'Нақш',
    roleUnset: 'муайян нашудааст',
    branchLabel: 'Филиал',
    revenueTodayTitle: 'Даромади имрӯз',
    visitsTodayTitle: 'Ташрифҳои имрӯз',
    pendingRequestsTitle: 'Дархостҳои интизор',
    pendingRequestsEmpty: 'Дархостҳои коркарднашуда аз uGym нестанд',
    pendingRequestsHint: 'Интизори тасдиқи пардохт дар хазина',
    goToRequestsButton: 'Ба дархостҳо',
    expiringSoonTitle: 'Дар 7 рӯз анҷом меёбанд',
    expiringSoonEmpty: 'Обунаҳои анҷомёбанда нестанд',
    expiringSoonHint: 'Обунаҳо барои ёдраскунии тамдид',
    goToExpiringButton: 'Ба анҷомёбандаҳо',
    openAnalyticsButton: 'Кушодани таҳлил',
    overviewErrorTitle: 'Хатогии боркунии хулоса',
    receiptsCountLabel: 'Чекҳо',
    membershipsLabel: 'Обунаҳо',
    manualVisitsLabel: 'Дастӣ',
    newClientsLabel: 'Мизоҷони нав',
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
    signOutLabel: 'Sign out',
    detailsLabel: 'Details',
    retryLabel: 'Retry',
    refreshLabel: 'Refresh',
    branchNotSelected: 'No branch selected',
    noCompanyTitle: 'You are not a gym staff member',
    noCompanyDescription:
        'Create your own company or open the uGym member app.',
    createCompanyCta: 'Create company (14-day free trial)',
    openClientAppCta: 'Open uGym member app',
    permissionDeniedTitle: 'Insufficient permissions',
    permissionDeniedDescription:
        'Access is restricted by your current company role.',
    subTabClients: 'Clients',
    subTabExpiring: 'Expiring',
    subTabTypes: 'Plans',
    subTabVisits: 'Visits',
    subTabRequests: 'Requests',
    subTabSales: 'Sales',
    subTabProducts: 'Products',
    subTabSchedule: 'Schedule',
    subTabTrainers: 'Trainers',
    subTabSettings: 'Settings',
    subTabStorefront: 'Storefront',
    subTabStaff: 'Staff',
    subTabAnnouncements: 'Announcements',
    subTabBilling: 'Subscription',
    receptionAndPosTitle: 'Reception & POS',
    scanClientQrButton: 'Scan client QR',
    kioskQrButton: 'Gym QR kiosk',
    openPosButton: 'Open POS',
    quickActionsTitle: 'Quick actions',
    roleLabel: 'Role',
    roleUnset: 'not assigned',
    branchLabel: 'Branch',
    revenueTodayTitle: 'Revenue today',
    visitsTodayTitle: 'Visits today',
    pendingRequestsTitle: 'Pending requests',
    pendingRequestsEmpty: 'No pending requests from uGym',
    pendingRequestsHint: 'Awaiting payment confirmation at POS',
    goToRequestsButton: 'View requests',
    expiringSoonTitle: 'Expiring in 7 days',
    expiringSoonEmpty: 'No memberships expiring soon',
    expiringSoonHint: 'Memberships to follow up for renewal',
    goToExpiringButton: 'View expiring',
    openAnalyticsButton: 'Open analytics',
    overviewErrorTitle: 'Failed to load summary',
    receiptsCountLabel: 'Receipts',
    membershipsLabel: 'Memberships',
    manualVisitsLabel: 'Manual',
    newClientsLabel: 'New clients',
  );

  static BusinessStrings of(AppLocale locale) {
    return switch (locale) {
      AppLocale.ru => ru,
      AppLocale.tg => tg,
      AppLocale.en => en,
    };
  }
}

/// Propagates the active [BusinessStrings] down the widget tree and pushed routes.
final class BusinessStringsScope extends InheritedWidget {
  const BusinessStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final BusinessStrings strings;

  /// Returns active strings from the nearest scope or defaults to [BusinessStrings.ru].
  static BusinessStrings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<BusinessStringsScope>();
    return scope?.strings ?? BusinessStrings.ru;
  }

  @override
  bool updateShouldNotify(BusinessStringsScope oldWidget) =>
      oldWidget.strings != strings;
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
