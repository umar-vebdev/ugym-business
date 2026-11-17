# uGym Business — чек-лист задач

**Текущий этап:** B1 — Авторизация, Онбординг, Киоск QR и Визиты
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

---

## Этап B1 — Авторизация, Онбординг, Киоск QR и Визиты

**ТЗ:** [uGym_Business_Mobile_TZ.md](specs/uGym_Business_Mobile_TZ.md) (разделы 2.4, 3–5.2, 6.1, 7.1), [identity-auth.yaml](api/identity-auth.yaml), [companies.yaml](api/companies.yaml), [visits-analytics.yaml](api/visits-analytics.yaml)

- [x] **B1-06b** Журнал визитов, ручная отметка (в т.ч. задним числом) и отмена за 24 ч с причиной (`VisitsLogScreen`, `ManualCheckInSheet`) + подключение экранов B1 в `BusinessShell` (39 тестов зелёные)
  - Проверка: widget-тесты журнала, ручной отметки и отмены

---

## Текущий этап: `B2` — CRM клиентов, Абонементы и Касса (`PaymentMark`)

- [x] **B2-01** Доменные модели и REST-репозиторий CRM клиентов (`ClientsRepository`, `RemoteClientsRepository`) — 4 теста зелёные
  - Цель: `GET /business/clients`, `POST /business/clients` (включая маппинг `409 CLIENT_PHONE_EXISTS`), `POST /business/clients/merge`
  - Проверка: unit-тесты `RemoteClientsRepository` с mock-адаптером Dio

- [x] **B2-02** UI CRM клиентов: список, поиск, быстрая регистрация и слияние дублей (`ClientsListScreen`, `CreateClientSheet`) — 3 теста зелёные
  - Цель: поиск по имени/телефону/email, бейдж `linked`, подсказка про email-привязку, обработка `409 CLIENT_PHONE_EXISTS`, слияние дублей только для `owner`
  - Проверка: widget-тесты поиска, создания, `409` и RBAC-ограничения `merge`

- [x] **B2-03** Доменные модели и REST-репозиторий тарифов и абонементов (`MembershipsRepository`, `RemoteMembershipsRepository`) — 4 теста зелёные
  - Цель: `membership-types` (`GET`/`POST`/`PATCH active`), `clients/{id}/memberships`, `memberships/expiring`, `freeze`/`unfreeze`/`cancel`
  - Проверка: unit-тесты `RemoteMembershipsRepository`

- [x] **B2-04** UI конструктора тарифов, истекающих за 7 дней и операций заморозки/отмены (`MembershipTypesScreen`, `CreateMembershipTypeScreen`, `ExpiringMembershipsTab`) — 3 теста зелёные
  - Цель: конструктор тарифов (`owner`), валидация `kind`/`start_mode`/`time_from`+`time_to`, список истекающих, `freeze`/`unfreeze` (`owner`/`admin`), `cancel` с причиной (`owner`)
  - Проверка: widget-тесты конструктора тарифов, истекающих абонементов и операций

- [x] **B2-05** Доменные модели и REST-репозиторий кассы, заявок и товаров (`SalesAndRequestsRepository`, `RemoteSalesAndRequestsRepository`) — 4 теста зелёные
  - Цель: `products` (`GET`/`POST`/`PATCH`), `sales` (`GET`/`POST` с `Idempotency-Key`, `refund`, `clients/{id}/sales`), `membership-requests` (`GET`, `pay` с `Idempotency-Key`, `cancel`)
  - Проверка: unit-тесты `RemoteSalesAndRequestsRepository`

- [x] **B2-06** UI кассы (`PosCheckoutScreen`), очереди заявок (`MembershipRequestsQueueTab`), истории продаж и склада товаров (`ProductsScreen`) — 3 теста зелёные
  - Цель: подтверждение/отмена заявок (`cash|card_terminal|transfer`, таймер `expires_at`), POS-касса с корзиной и валютой зала, возвраты (`owner`), склад товаров
  - Проверка: widget-тесты заявок, кассы, возвратов и склада

- [x] **B2-07** Карточка клиента 360° (`ClientDetailScreen`) и интеграция `B2` в `BusinessShell` (62 теста зелёные)
  - Цель: вкладки Абонементы/Посещения/Чеки + быстрые кнопки в `ClientDetailScreen`; подключение экранов `B2` во вкладки `Клиенты` и `Операции` в `BusinessShell` и `UgymBusinessApp`
  - Проверка: widget-тесты `ClientDetailScreen` и `BusinessShell` + полный прогон `dart format`, `flutter analyze`, `flutter test`

---

## Текущий этап: `B3` — Расписание, Тренеры, Витрина, Штат и Аналитика

- [x] **B3-01** Доменные модели и REST-репозиторий тренеров и расписания (`TrainersScheduleRepository`, `RemoteTrainersScheduleRepository`) — 3 теста зелёные
  - Цель: `/business/trainers`, `/business/schedule/templates`, `/business/schedule/sessions` (`GET`, `generate`, `cancel`, `bookings`)
  - Проверка: unit-тесты `RemoteTrainersScheduleRepository`

- [ ] **B3-02** UI тренеров, шаблонов, генерации до 62 дней, отмены и записей (`TrainersScreen`, `ScheduleTab`, `SessionBookingsScreen`)
  - Цель: CRUD тренеров (`owner`), шаблоны (`weekday`, `HH:MM`, `duration`, `capacity`), мастер генерации (<=62 дн.), отмена с возвратом визитов, просмотр `bookings` (включая `trainer`)
  - Проверка: widget-тесты шаблонов, генерации, отмены и `bookings`

- [ ] **B3-03** Доменные модели и REST-репозиторий витрины, фото и штата (`StorefrontAndStaffRepository`, `RemoteStorefrontAndStaffRepository`)
  - Цель: `gyms/{gym}/profile` (`PUT`, `submit`), `publication` (`PATCH`), `photos` (`POST` multipart, `DELETE`), `staff` (`GET`, `POST`, `PATCH`, `DELETE`)
  - Проверка: unit-тесты `RemoteStorefrontAndStaffRepository`

- [ ] **B3-04** UI редактора витрины и фотогалереи до 10 фото (`StorefrontEditorScreen`, `GymPhotosManager`)
  - Цель: редактирование профиля, предупреждение `approved -> draft`, блокировка в `pending`, отправка на модерацию, публикация при `approved`, загрузка/удаление до 10 фото
  - Проверка: widget-тесты статусов модерации, публикации и лимита фото

- [ ] **B3-05** UI штата сотрудников по email (`StaffManagementScreen`, `owner` only)
  - Цель: список штата, приглашение по email с памяткой при `400 BAD_REQUEST`, смена роли `admin <-> trainer`, удаление
  - Проверка: widget-тесты приглашения, ошибки `400`, смены роли и удаления

- [ ] **B3-06** Доменные модели и REST-репозиторий аналитики, рассылок и подписки (`AnalyticsAndBillingRepository`, `RemoteAnalyticsAndBillingRepository`)
  - Цель: `analytics/overview`, `analytics/revenue`, `notifications/announcements` (`202`), `billing/subscription`, `billing/plans`
  - Проверка: unit-тесты `RemoteAnalyticsAndBillingRepository`

- [ ] **B3-07** UI аналитики владельца, рассылок и подписки (`AnalyticsScreen`, `AnnouncementsScreen`, `BillingStatusScreen`)
  - Цель: фильтры периода и `inactive_days`, сводка и отчёт выручки (`owner`), рассылка `push`/`sms` (`owner`/`admin`), статус подписки платформы
  - Проверка: widget-тесты аналитики, рассылок и биллинга

- [ ] **B3-08** Интеграция экранов `B3` в `BusinessShell` и `UgymBusinessApp`
  - Цель: подключение расписания, аналитики, витрины, штата, рассылок и биллинга в `BusinessShell` / `main.dart` с проверкой RBAC
  - Проверка: интеграционные widget-тесты `B3` + полный прогон `dart format`, `flutter analyze`, `flutter test`

---

## Будущие этапы (эпики — раскрыть перед стартом каждого)

- [ ] **B4 — Полировка UX, Режим чтения, QA и Релиз** (Тесты RBAC и `SUBSCRIPTION_EXPIRED`, устойчивость к потере сети, iPad/tablet адаптация, `PrivacyInfo.xcprivacy`, Data Safety, TestFlight / Google Play)
