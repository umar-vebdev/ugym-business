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

---

## Этап B1 — Авторизация, Онбординг, Киоск QR и Визиты

**ТЗ:** [uGym_Business_Mobile_TZ.md](specs/uGym_Business_Mobile_TZ.md) (разделы 2.4, 3–5.2, 6.1, 7.1), [identity-auth.yaml](api/identity-auth.yaml), [companies.yaml](api/companies.yaml), [visits-analytics.yaml](api/visits-analytics.yaml)

- [ ] **B1-02** Экраны входа, регистрации с Email OTP, сброса пароля и выхода (`AuthController`, `LoginScreen`, `RegisterUserScreen`, `EmailOtpVerifyScreen`, `ResetPasswordScreen`)
  - Проверка: widget-тесты потоков входа, OTP, сброса пароля и выхода в Light/Dark темах
- [ ] **B1-03** Онбординг компании (`POST /business/companies` для `noCompany` → `owner`), управление филиалами (`POST/PATCH /business/gyms`) и валюта компании (`currencies`, `PATCH /company/currency`)
  - Проверка: unit- и widget-тесты онбординга, создания/правки зала и смены валюты
- [ ] **B1-04** Домен и слой данных ресепшна и визитов (`GymQrPayload`, `CheckInResult`, `VisitRecord`, `ReceptionVisitsRepository`: `qr`, `check-in-qr` с `Idempotency-Key`, `visits`, ручной чекин, отмена за 24 ч)
  - Проверка: unit-тесты репозитория и сохранения `Idempotency-Key` при повторах
- [ ] **B1-05** Киоск-режим QR зала (`GymQrKioskScreen`: 60с обратный отсчёт, автообновление токена, PIN-блокировка выхода с хешем в `TokenStorage`)
  - Проверка: widget-тесты таймера обновления и PIN-блокировки выхода
- [ ] **B1-06** Рабочее место ресепшна (`ReceptionDeskScreen`: сканер QR клиента с защитой от дублей, экран успеха/отказа `422`, журнал визитов, ручная отметка и отмена за 24 ч)
  - Проверка: widget-тесты чекина, отказа `422`, ручной отметки и отмены

---

## Будущие этапы (эпики — раскрыть перед стартом каждого)

- [ ] **B2 — CRM клиентов, Абонементы и Касса (`PaymentMark`)** (Поиск/создание клиента, Карточка 360°, Слияние дублей `owner`, Истекающие за 7 дней, Заморозка/разморозка/отмена, Конструктор тарифов, Заявки `pay`/`cancel`, Касса `POST /sales`, Возвраты `refund`, Товары)
- [ ] **B3 — Расписание, Тренеры, Витрина, Штат и Аналитика** (Тренеры, Шаблоны и генерация до 62 дней, Отмена занятия, Экран тренера, Витрина + до 10 фото + модерация + публикация, Штат по email, Аналитика `overview`/`revenue`, Рассылки, Подписка платформы)
- [ ] **B4 — Полировка UX, Режим чтения, QA и Релиз** (Тесты RBAC и `SUBSCRIPTION_EXPIRED`, устойчивость к потере сети, iPad/tablet адаптация, `PrivacyInfo.xcprivacy`, Data Safety, TestFlight / Google Play)
