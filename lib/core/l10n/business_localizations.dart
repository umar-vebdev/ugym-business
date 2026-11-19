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
    required this.cancelLabel,
    required this.authEmailOrPhoneLabel,
    required this.authPasswordLabel,
    required this.authSignInButton,
    required this.authCreateAccountButton,
    required this.authResetPasswordButton,
    required this.authPhoneOptionalLabel,
    required this.authPasswordMinLabel,
    required this.authRegisterButton,
    required this.authBackToLoginButton,
    required this.authOtpCodeLabel,
    required this.authVerifyEmailButton,
    required this.authResendOtpButton,
    required this.authSendCodeButton,
    required this.authNewPasswordLabel,
    required this.authSaveNewPasswordButton,
    required this.authSubtitleLogin,
    required this.authSubtitleRegister,
    required this.authSubtitleOtp,
    required this.authSubtitleReset,
    required this.scannerCheckingMembership,
    required this.scannerCameraHint,
    required this.scannerVisitRecorded,
    required this.scannerMembershipPrefix,
    required this.scannerRemainingVisitsPrefix,
    required this.scannerScanNextButton,
    required this.scannerAcceptPaymentButton,
    required this.scannerOpenClientsButton,
    required this.scannerNetworkErrorTitle,
    required this.scannerNetworkRetryHint,
    required this.scannerRefusalNoActive,
    required this.scannerRefusalFrozen,
    required this.scannerRefusalDailyLimit,
    required this.scannerRefusalOutsideTime,
    required this.scannerRefusalInvalidQr,
    required this.scannerRefusalGeneric,
    required this.kioskLockedBadge,
    required this.kioskModeBadge,
    required this.kioskLoadingQr,
    required this.kioskScanPrompt,
    required this.kioskRefreshPrefix,
    required this.kioskSecondsSuffix,
    required this.kioskSlotPrefix,
    required this.kioskSetPinLabel,
    required this.kioskEnableLockButton,
    required this.kioskLockWithPinButton,
    required this.kioskExitButton,
    required this.kioskUnlockPinLabel,
    required this.kioskConfirmPinButton,
    required this.kioskUnlockAndExitButton,
    required this.kioskPinFormatError,
    required this.kioskWrongPinError,
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
  final String cancelLabel;
  final String authEmailOrPhoneLabel;
  final String authPasswordLabel;
  final String authSignInButton;
  final String authCreateAccountButton;
  final String authResetPasswordButton;
  final String authPhoneOptionalLabel;
  final String authPasswordMinLabel;
  final String authRegisterButton;
  final String authBackToLoginButton;
  final String authOtpCodeLabel;
  final String authVerifyEmailButton;
  final String authResendOtpButton;
  final String authSendCodeButton;
  final String authNewPasswordLabel;
  final String authSaveNewPasswordButton;
  final String authSubtitleLogin;
  final String authSubtitleRegister;
  final String authSubtitleOtp;
  final String authSubtitleReset;
  final String scannerCheckingMembership;
  final String scannerCameraHint;
  final String scannerVisitRecorded;
  final String scannerMembershipPrefix;
  final String scannerRemainingVisitsPrefix;
  final String scannerScanNextButton;
  final String scannerAcceptPaymentButton;
  final String scannerOpenClientsButton;
  final String scannerNetworkErrorTitle;
  final String scannerNetworkRetryHint;
  final String scannerRefusalNoActive;
  final String scannerRefusalFrozen;
  final String scannerRefusalDailyLimit;
  final String scannerRefusalOutsideTime;
  final String scannerRefusalInvalidQr;
  final String scannerRefusalGeneric;
  final String kioskLockedBadge;
  final String kioskModeBadge;
  final String kioskLoadingQr;
  final String kioskScanPrompt;
  final String kioskRefreshPrefix;
  final String kioskSecondsSuffix;
  final String kioskSlotPrefix;
  final String kioskSetPinLabel;
  final String kioskEnableLockButton;
  final String kioskLockWithPinButton;
  final String kioskExitButton;
  final String kioskUnlockPinLabel;
  final String kioskConfirmPinButton;
  final String kioskUnlockAndExitButton;
  final String kioskPinFormatError;
  final String kioskWrongPinError;

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
    cancelLabel: 'Отмена',
    authEmailOrPhoneLabel: 'Email или телефон',
    authPasswordLabel: 'Пароль',
    authSignInButton: 'Войти',
    authCreateAccountButton: 'Создать аккаунт',
    authResetPasswordButton: 'Сбросить пароль',
    authPhoneOptionalLabel: 'Телефон (необязательно)',
    authPasswordMinLabel: 'Пароль (минимум 8 символов)',
    authRegisterButton: 'Зарегистрироваться',
    authBackToLoginButton: 'Назад ко входу',
    authOtpCodeLabel: '6-значный код из письма',
    authVerifyEmailButton: 'Подтвердить email',
    authResendOtpButton: 'Отправить код повторно',
    authSendCodeButton: 'Получить код на email',
    authNewPasswordLabel: 'Новый пароль',
    authSaveNewPasswordButton: 'Сохранить новый пароль',
    authSubtitleLogin: 'Вход для владельца, администратора и тренера',
    authSubtitleRegister: 'Регистрация аккаунта сотрудника или владельца',
    authSubtitleOtp: 'Подтверждение email по одноразовому коду',
    authSubtitleReset: 'Восстановление доступа по коду из письма',
    scannerCheckingMembership: 'Проверяем абонемент...',
    scannerCameraHint:
        'Наведите камеру на личный QR-код клиента из приложения uGym',
    scannerVisitRecorded: 'Посещение отмечено',
    scannerMembershipPrefix: 'Абонемент №',
    scannerRemainingVisitsPrefix: 'Осталось занятий: ',
    scannerScanNextButton: 'Сканировать следующего',
    scannerAcceptPaymentButton: 'Принять оплату',
    scannerOpenClientsButton: 'Открыть клиентов',
    scannerNetworkErrorTitle: 'Нет связи с сервером',
    scannerNetworkRetryHint:
        'Нажмите «Повторить» — дубль посещения не будет создан.',
    scannerRefusalNoActive: 'Нет активного абонемента',
    scannerRefusalFrozen: 'Абонемент заморожен',
    scannerRefusalDailyLimit: 'Лимит входов на сегодня исчерпан',
    scannerRefusalOutsideTime: 'Вне разрешённого времени абонемента',
    scannerRefusalInvalidQr: 'QR-код недействителен или устарел',
    scannerRefusalGeneric: 'Посещение не отмечено',
    kioskLockedBadge: 'Киоск заблокирован',
    kioskModeBadge: 'Режим стойки',
    kioskLoadingQr: 'Загрузка QR-кода зала...',
    kioskScanPrompt: 'Отсканируйте код в приложении uGym',
    kioskRefreshPrefix: 'Обновление через ',
    kioskSecondsSuffix: ' сек',
    kioskSlotPrefix: 'Слот #',
    kioskSetPinLabel: 'PIN-код из 4 цифр для выхода',
    kioskEnableLockButton: 'Включить блокировку киоска',
    kioskLockWithPinButton: 'Заблокировать киоск PIN-кодом',
    kioskExitButton: 'Выйти из режима киоска',
    kioskUnlockPinLabel: 'Введите 4-значный PIN сотрудника',
    kioskConfirmPinButton: 'Подтвердить PIN',
    kioskUnlockAndExitButton: 'Разблокировать и выйти',
    kioskPinFormatError: 'Введите 4 цифры PIN-кода',
    kioskWrongPinError: 'Неверный PIN-код',
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
    cancelLabel: 'Бекор кардан',
    authEmailOrPhoneLabel: 'Email ё телефон',
    authPasswordLabel: 'Рамз',
    authSignInButton: 'Ворид шудан',
    authCreateAccountButton: 'Сохтани ҳисоб',
    authResetPasswordButton: 'Барқарор кардани рамз',
    authPhoneOptionalLabel: 'Телефон (ихтиёрӣ)',
    authPasswordMinLabel: 'Рамз (ҳадди ақал 8 аломат)',
    authRegisterButton: 'Бақайдгирӣ',
    authBackToLoginButton: 'Бозгашт ба воридшавӣ',
    authOtpCodeLabel: 'Рамзи 6-рақама аз почта',
    authVerifyEmailButton: 'Тасдиқи email',
    authResendOtpButton: 'Аз нав фиристодани рамз',
    authSendCodeButton: 'Гирифтани рамз ба email',
    authNewPasswordLabel: 'Рамзи нав',
    authSaveNewPasswordButton: 'Нигоҳ доштани рамзи нав',
    authSubtitleLogin: 'Воридшавӣ барои соҳиб, маъмур ва мураббӣ',
    authSubtitleRegister: 'Бақайдгирии ҳисоби корманд ё соҳиб',
    authSubtitleOtp: 'Тасдиқи email бо рамзи якдафъаина',
    authSubtitleReset: 'Барқарорсозии дастрасӣ бо рамз аз почта',
    scannerCheckingMembership: 'Обуна санҷида мешавад...',
    scannerCameraHint:
        'Камераро ба QR-рамзи шахсии мизоҷ дар барномаи uGym равона кунед',
    scannerVisitRecorded: 'Ташриф сабт шуд',
    scannerMembershipPrefix: 'Обуна №',
    scannerRemainingVisitsPrefix: 'Машғулиятҳои боқимонда: ',
    scannerScanNextButton: 'Скан кардани навбатӣ',
    scannerAcceptPaymentButton: 'Қабули пардохт',
    scannerOpenClientsButton: 'Кушодани мизоҷон',
    scannerNetworkErrorTitle: 'Пайваст бо сервер нест',
    scannerNetworkRetryHint:
        '«Такрор кардан»-ро пахш кунед — ташрифи такрорӣ сохта намешавад.',
    scannerRefusalNoActive: 'Обунаи фаъол нест',
    scannerRefusalFrozen: 'Обуна яхбандӣ шудааст',
    scannerRefusalDailyLimit: 'Лимити вуруд барои имрӯз тамом шуд',
    scannerRefusalOutsideTime: 'Берун аз вақти иҷозатшудаи обуна',
    scannerRefusalInvalidQr: 'QR-рамз нодуруст ё кӯҳна шудааст',
    scannerRefusalGeneric: 'Ташриф сабт нашуд',
    kioskLockedBadge: 'Киоск қулф шудааст',
    kioskModeBadge: 'Реҷаи пештахта',
    kioskLoadingQr: 'Боркунии QR-рамзи толор...',
    kioskScanPrompt: 'Рамзро дар барномаи uGym скан кунед',
    kioskRefreshPrefix: 'Навсозӣ пас аз ',
    kioskSecondsSuffix: ' сон',
    kioskSlotPrefix: 'Слот #',
    kioskSetPinLabel: 'PIN-рамзи 4-рақама барои баромад',
    kioskEnableLockButton: 'Фаъол кардани қулфи киоск',
    kioskLockWithPinButton: 'Қулф кардани киоск бо PIN',
    kioskExitButton: 'Баромадан аз реҷаи киоск',
    kioskUnlockPinLabel: 'PIN-и 4-рақамаи кормандро ворид кунед',
    kioskConfirmPinButton: 'Тасдиқи PIN',
    kioskUnlockAndExitButton: 'Кушодан ва баромадан',
    kioskPinFormatError: '4 рақами PIN-рамзро ворид кунед',
    kioskWrongPinError: 'PIN-рамз нодуруст аст',
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
    cancelLabel: 'Cancel',
    authEmailOrPhoneLabel: 'Email or phone',
    authPasswordLabel: 'Password',
    authSignInButton: 'Sign in',
    authCreateAccountButton: 'Create account',
    authResetPasswordButton: 'Reset password',
    authPhoneOptionalLabel: 'Phone (optional)',
    authPasswordMinLabel: 'Password (min 8 characters)',
    authRegisterButton: 'Register',
    authBackToLoginButton: 'Back to sign in',
    authOtpCodeLabel: '6-digit email code',
    authVerifyEmailButton: 'Verify email',
    authResendOtpButton: 'Resend code',
    authSendCodeButton: 'Send code to email',
    authNewPasswordLabel: 'New password',
    authSaveNewPasswordButton: 'Save new password',
    authSubtitleLogin: 'Sign in for owner, admin, and trainer',
    authSubtitleRegister: 'Register a staff or owner account',
    authSubtitleOtp: 'Verify email with one-time code',
    authSubtitleReset: 'Restore access using the email code',
    scannerCheckingMembership: 'Checking membership...',
    scannerCameraHint:
        'Point the camera at the client personal QR code in the uGym app',
    scannerVisitRecorded: 'Visit recorded',
    scannerMembershipPrefix: 'Membership #',
    scannerRemainingVisitsPrefix: 'Remaining visits: ',
    scannerScanNextButton: 'Scan next',
    scannerAcceptPaymentButton: 'Accept payment',
    scannerOpenClientsButton: 'Open clients',
    scannerNetworkErrorTitle: 'No server connection',
    scannerNetworkRetryHint: 'Tap Retry — no duplicate visit will be created.',
    scannerRefusalNoActive: 'No active membership',
    scannerRefusalFrozen: 'Membership is frozen',
    scannerRefusalDailyLimit: 'Daily check-in limit reached',
    scannerRefusalOutsideTime: 'Outside allowed membership hours',
    scannerRefusalInvalidQr: 'QR code is invalid or expired',
    scannerRefusalGeneric: 'Check-in refused',
    kioskLockedBadge: 'Kiosk locked',
    kioskModeBadge: 'Desk mode',
    kioskLoadingQr: 'Loading gym QR code...',
    kioskScanPrompt: 'Scan this code in the uGym app',
    kioskRefreshPrefix: 'Refreshing in ',
    kioskSecondsSuffix: ' s',
    kioskSlotPrefix: 'Slot #',
    kioskSetPinLabel: '4-digit exit PIN',
    kioskEnableLockButton: 'Enable kiosk lock',
    kioskLockWithPinButton: 'Lock kiosk with PIN',
    kioskExitButton: 'Exit kiosk mode',
    kioskUnlockPinLabel: 'Enter 4-digit staff PIN',
    kioskConfirmPinButton: 'Confirm PIN',
    kioskUnlockAndExitButton: 'Unlock and exit',
    kioskPinFormatError: 'Enter a 4-digit PIN',
    kioskWrongPinError: 'Incorrect PIN',
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
