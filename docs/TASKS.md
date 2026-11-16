# uGym Business — чек-лист задач

**Текущий этап:** B0 — Фундамент проекта
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

---

## Этап B0 — Фундамент проекта

**ТЗ:** [uGym_Business_Mobile_TZ.md](../specs/uGym_Business_Mobile_TZ.md) (разделы 1, 2, 6.2, 7.1), [uCraft_Design_System.md](../specs/uCraft_Design_System.md) (разделы 2–9, 13, 18, 20–22)

- [ ] **B0-04** Локализация `ru` / `tg` / `en` (ARB), адаптивный навигационный каркас (Bottom Navigation для `<600dp` и Navigation Rail / Sidebar для планшетов `>=600dp`) и проверка `GET /api/v1/health`
  - Проверка: `dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

---

## Будущие этапы (эпики — раскрыть перед стартом каждого)

- [ ] **B1 — Авторизация, Онбординг, Киоск QR и Визиты** (Login, Register + Email OTP, Reset Password, Logout, Онбординг компании, Киоск-режим QR зала 60с + WakeLock + PIN выхода, Сканер QR клиента `check-in-qr`, Журнал визитов, Ручной чекин и отмена 24ч)
- [ ] **B2 — CRM клиентов, Абонементы и Касса (`PaymentMark`)** (Поиск/создание клиента, Карточка 360°, Слияние дублей `owner`, Истекающие за 7 дней, Заморозка/разморозка/отмена, Конструктор тарифов, Заявки `pay`/`cancel`, Касса `POST /sales`, Возвраты `refund`, Товары)
- [ ] **B3 — Расписание, Тренеры, Витрина, Штат и Аналитика** (Тренеры, Шаблоны и генерация до 62 дней, Отмена занятия, Экран тренера, Витрина + до 10 фото + модерация + публикация, Штат по email, Аналитика `overview`/`revenue`, Рассылки, Подписка платформы)
- [ ] **B4 — Полировка UX, Режим чтения, QA и Релиз** (Тесты RBAC и `SUBSCRIPTION_EXPIRED`, устойчивость к потере сети, iPad/tablet адаптация, `PrivacyInfo.xcprivacy`, Data Safety, TestFlight / Google Play)
