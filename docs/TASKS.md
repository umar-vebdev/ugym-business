# uGym Business — чек-лист задач

**Текущий этап:** B4 — Полировка UX, Режим чтения, QA и Релиз
**Статусы:** `[ ]` не начата · `[~]` в работе · `[x]` готова · `[!]` заблокирована (причина в заметках)

## Правила ведения файла

- Нумерация: `B{этап}-{номер}`, подзадачи `B0-02a`, `B0-02b`.
- Завершённые задачи сворачиваются в одну строку в разделе «Готово».
- Подробное описание — только для активного этапа. Будущие этапы хранятся как эпики и раскрываются перед стартом.
- Одна задача = одна вещь, до ~5 файлов, проверяется командами `dart format`, `flutter analyze`, `flutter test`.

---

## Готово

- [x] **B0-01** (заметка: `flutter create` в Flutter 3.50 добавил `material_ui: ^1.1.0` в `pubspec.yaml` и исключения `android/**`, `ios/**` в `analysis_options.yaml`) Инициализирован Flutter-проект `uGym Business` (`tj.ugym.business` в `build.gradle.kts`, `MainActivity.kt`, `Info.plist`, `project.pbxproj`), настроены строгие правила `analysis_options.yaml`, `AppConfig` (`dev`/`staging`/`prod`), стартовый экран в `lib/main.dart` и 2 теста в `test/widget_test.dart` (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B0-02** (заметка: `ugym_core` переведён на `material_ui: ^1.1.0` по `D-003` для полной совместимости типов `ThemeData` в Flutter 3.50) Подключён общий пакет `ugym_core` (`path: ../ugym_core`, `D-002`), реализованы `AppPreferences` поверх `TokenStorage`, `ThemeController` (Light по умолчанию, сохранение Light/Dark/System) и `BusinessApiClient`, подключены `UcraftTheme.light()` / `UcraftTheme.dark()` в `lib/main.dart`; 4 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B0-03** (заметка: в `ugym_core/lib/ugym_core.dart` реэкспортированы типы `Dio`, чтобы не нарушать `depend_on_referenced_packages`; в `docs/api/` добавлен `platform.yaml` для биллинга) Реализованы матрица RBAC (`BusinessRole` / `BusinessPermission` для `owner`/`admin`/`trainer`/`noCompany`), `GymSummary`, `BusinessSessionController` (`bootstrapFromApi`, `isReadOnly` при `SUBSCRIPTION_EXPIRED`, выбор филиала), а также `SubscriptionReadOnlyBanner`, `RoleGuard` и `GymBranchSelector`; 11 тестов зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B0-04** (заметка: в `ugym_core` добавлен общий `UgymHealthService` / `UgymHealthStatus` для `GET /api/v1/health`) Реализованы ARB-словари (`app_ru.arb`, `app_tg.arb`, `app_en.arb`), `BusinessStrings` и `LocaleController` с переключением языка на лету, адаптивный `BusinessShell` (`NavigationBar` на `<600dp` и `NavigationRail` на `>=600dp`, фильтрация вкладок по ролям, баннер чтения, селектор филиала, смена темы и проверка `/health`); 13 тестов зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B1-01** Реализованы доменные модели и контракт аутентификации (`AuthenticatedUser`, `AuthRepository` на чистом Dart) и `RemoteAuthRepository` (`login` с сохранением токена в `TokenStorage`, `register`, `send-otp`, `verify-email`, `reset-password`, `logout` с гарантированной очисткой токена и `GET /user`); 18 тестов зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B1-02** Реализованы `AuthController` (вход по email/телефону, восстановление сессии `tryRestoreSession`, регистрация + OTP, сброс пароля, выход со сбросом роли) и `AuthFlowScreen` в стиле uCraft 1.0 + кнопка «Выйти» в `BusinessShell` и привязка в `lib/main.dart`; 21 тест зелёный (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B1-03** Реализованы доменные модели и контракт онбординга (`CreatedCompanyResult`, `GymBranch`, `CurrencyOption`, `CompanyOnboardingRepository`), `RemoteCompanyOnboardingRepository` (`POST /business/companies`, `GET/POST/PATCH /business/gyms`, `currencies`, `PATCH /company/currency`), экран `CompanyOnboardingCard` (перевод `noCompany` → `owner` + 14-дневный триал) и `CompanyBranchesAndCurrencyCard` (управление филиалами, геозоной `50..5000` м и валютой); 24 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B1-04** Реализованы доменные модели и контракт ресепшна/визитов (`VisitMethod`, `VisitStatus`, `GymQrToken`, `CheckInResult`, `VisitRecord` с проверкой 24-часовой отмены `canCancelAt`, `ReceptionVisitsRepository`) и `RemoteReceptionVisitsRepository` (`/gyms/{id}/qr`, `/check-in-qr` с `Idempotency-Key`, `/visits`, `/clients/{id}/visits`, `/visits/{id}/cancel`); 27 тестов зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B1-05** Добавлены `crypto`, `qr_flutter`, `wakelock_plus` (`D-003`); реализованы `KioskWakeLock` (`PlatformKioskWakeLock` / `NoOpKioskWakeLock`), `KioskPinGuard` (SHA-256 + случайная соль в `TokenStorage`) и `GymQrKioskScreen` (QR-матрица `QrImageView`, 60с отсчёт, автообновление за 4с до `expiresAt`, остановка таймера и отключение WakeLock при выходе, PIN-блокировка `PopScope`); 30 тестов зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B1-06a** (заметка: задача `B1-06` разбита на `a`/`b` по правилу ≤5 файлов) Добавлен `mobile_scanner` (`D-004`); реализованы `QrScannerBuilder` (камера подменяется в тестах), `ReceptionScanController` (пауза сканера на время запроса, повтор после сбоя сети с тем же токеном и `Idempotency-Key`, новый ключ для следующего клиента) и `ScanClientQrScreen` (карточка успеха с остатком занятий, крупные экраны отказа для всех кодов `422`, кнопка «Принять оплату» при `NO_ACTIVE_MEMBERSHIP`); 35 тестов зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B1-06b** Журнал визитов, ручная отметка (в т.ч. задним числом) и отмена за 24 ч с причиной (`VisitsLogScreen`, `ManualCheckInSheet`) + подключение экранов B1 в `BusinessShell`; 39 тестов зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B2-01** Доменные модели и REST-репозиторий CRM клиентов (`ClientsRepository`, `RemoteClientsRepository`); 4 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B2-02** UI CRM клиентов: список, поиск, быстрая регистрация, обработка `409 CLIENT_PHONE_EXISTS` и слияние дублей `owner` (`ClientsListScreen`, `CreateClientSheet`); 3 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B2-03** Доменные модели и REST-репозиторий тарифов и абонементов (`MembershipsRepository`, `RemoteMembershipsRepository`); 4 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B2-04** UI конструктора тарифов, истекающих за 7 дней и операций `freeze`/`unfreeze`/`cancel` (`MembershipTypesScreen`, `CreateMembershipTypeScreen`, `ExpiringMembershipsTab`); 3 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B2-05** Доменные модели и REST-репозиторий кассы, заявок и товаров (`SalesAndRequestsRepository`, `RemoteSalesAndRequestsRepository`); 4 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B2-06** UI кассы (`PosCheckoutScreen`), очереди заявок (`MembershipRequestsQueueTab`), истории продаж (`SalesHistoryTab`) и склада товаров (`ProductsScreen`); 3 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B2-07** Карточка клиента 360° (`ClientDetailScreen`) и интеграция экранов `B2` в `BusinessShell` и `UgymBusinessApp`; 62 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B3-01** Доменные модели и REST-репозиторий тренеров и расписания (`TrainersScheduleRepository`, `RemoteTrainersScheduleRepository`); 3 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B3-02** UI тренеров, шаблонов, генерации до 62 дней, отмены с возвратом визитов и записей группы (`TrainersScreen`, `ScheduleTab`, `SessionBookingsScreen`); 3 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B3-03** Доменные модели и REST-репозиторий витрины, фото и штата (`StorefrontAndStaffRepository`, `RemoteStorefrontAndStaffRepository`); 3 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B3-04** UI редактора витрины, статусов модерации, публикации и фотогалереи до 10 фото (`StorefrontEditorScreen`, `GymPhotosManager`); 2 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B3-05** UI штата сотрудников по подтверждённому email с памяткой при `400 BAD_REQUEST` (`StaffManagementScreen`, `owner` only); 1 тест зелёный (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B3-06** Доменные модели и REST-репозиторий аналитики, рассылок и подписки (`AnalyticsAndBillingRepository`, `RemoteAnalyticsAndBillingRepository`); 3 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B3-07** UI аналитики владельца, рассылок `push`/`sms` и статуса подписки платформы без IAP (`AnalyticsScreen`, `AnnouncementsScreen`, `BillingStatusScreen`); 3 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).
- [x] **B3-08** Интеграция экранов `B3` (`ScheduleTab`, `TrainersScreen`, `AnalyticsScreen`, `StorefrontEditorScreen`, `StaffManagementScreen`, `AnnouncementsScreen`, `BillingStatusScreen`) в `BusinessShell` и `UgymBusinessApp` с RBAC для `owner`/`admin`/`trainer`; 83 теста зелёные (`format ✓`, `analyze ✓`, `test ✓`).

---

## Текущий этап: `B4` — Полировка UX, Режим чтения, QA и Релиз

**ТЗ:** [uGym_Business_Mobile_TZ.md](specs/uGym_Business_Mobile_TZ.md) (разделы 0.2, 1, 2.1, 3.2, 6, 7), [uCraft_Design_System.md](specs/uCraft_Design_System.md) (разделы 16, 18, 19, 20, 23)

- [ ] **B4-01** End-to-end аудит и тесты RBAC (`owner`/`admin`/`trainer`), онбординга/доступа тренера к филиалу и режима «только чтение» (`SUBSCRIPTION_EXPIRED`)
  - Цель: проверить перехват `403 SUBSCRIPTION_EXPIRED`, блокировку мутаций во всех модулях `B1`–`B3`, переход с баннера чтения в статус подписки и доступ тренера к расписанию
  - Проверка: unit/widget-тесты RBAC и `SUBSCRIPTION_EXPIRED`
- [ ] **B4-02** Сетевая устойчивость и строгая идемпотентность (`Idempotency-Key` при повторе, обработка `429 Retry-After` и потери сети)
  - Цель: проверить и укрепить сохранение `Idempotency-Key` при ретраях кассы (`POST /sales`, `membership-requests/{id}/pay`), ручного чекина и сканера QR, а также отображение `Retry-After`
  - Проверка: unit/widget-тесты повторных отправок без дублей и сетевых ошибок
- [ ] **B4-03** Адаптивность iPad/tablet (`>=600dp`, `>=840dp`), Light/Dark темы, ARB-локализация (`ru`/`tg`/`en`) и состояния экранов
  - Цель: проверить планшетную раскладку киоска/shell, обе темы uCraft, переключение `ru`/`tg`/`en` и состояния `loading`/`empty`/`error`/`permission-denied`
  - Проверка: widget-тесты на планшетных и компактных размерах, темах и локалях
- [ ] **B4-04** Релизная подготовка iOS/Android и итоговый приёмочный чек-лист
  - Цель: проверить/добавить `PrivacyInfo.xcprivacy`, `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` в `Info.plist`, разрешения в `AndroidManifest.xml`, подтвердить отсутствие IAP/внешних ссылок оплаты и пройти приёмочный чек-лист (п. 7.2 ТЗ)
  - Проверка: ревью манифестов/конфигураций + полный прогон `dart format`, `flutter analyze`, `flutter test`
