# Handoff — uGym Business (Business App)

**Обновлено:** 2026-11-16
**Текущий этап:** B0 — Фундамент проекта (завершён)
**Текущая задача:** Все задачи этапа `B0` завершены (`B0-01`–`B0-04` `[x]`)

## Что сделано в последней сессии

- **`B0-01`**: инициализирован Flutter-проект `uGym Business` (`tj.ugym.business`), настроены строгие правила `analysis_options.yaml` и `AppConfig` (`dev`/`staging`/`prod`).
- **`B0-02`**: подключён пакет `ugym_core` (`path: ../ugym_core`, `D-002`; `D-003` на `material_ui: ^1.1.0`), реализованы `AppPreferences`, `ThemeController` (Light по умолчанию, Light/Dark/System) и `BusinessApiClient`.
- **`B0-03`**: реализованы RBAC (`BusinessRole`, `BusinessPermission`), `GymSummary`, `BusinessSessionController` (`bootstrapFromApi`, `isReadOnly` при `SUBSCRIPTION_EXPIRED`, выбор филиала), виджеты `SubscriptionReadOnlyBanner`, `RoleGuard` и `GymBranchSelector`.
- **`B0-04`**: добавлены ARB-словари (`ru`, `tg`, `en`), `LocaleController` + `BusinessStrings` с переключением на лету, адаптивный `BusinessShell` (`NavigationBar` `<600dp` / `NavigationRail` `>=600dp`, фильтрация разделов по ролям) и проверка связи через `UgymHealthService`.
- Все проверки пройдены: `dart format` ✓, `flutter analyze` ✓ (`No issues found!`), `flutter test` ✓ (`13 passed`).

## Актуальное состояние окружения

- Flutter SDK `3.50.0` и Dart SDK `3.14.0` установлены; локальное тестирование и статический анализ работают полностью.
- Для сборки APK/запуска на телефоне позже понадобится Android SDK (`flutter doctor`).

## Точный следующий шаг

- Раскрыть эпик **`B1`** (Авторизация, Онбординг компании, Киоск QR 60с и Визиты) на мелкие задачи в `docs/TASKS.md` и согласовать план с разработчиком, либо начать этап **`M0`** в `/home/umar/ugym-mobile/uGym`.
