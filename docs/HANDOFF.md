# Handoff — uGym Business (Business App)

**Обновлено:** 2026-11-16
**Текущий этап:** B0 — Фундамент проекта
**Текущая задача:** `B0-03` `[x]` завершена; следующая — `B0-04`

## Что сделано в последней сессии

- **`B0-01`**: инициализирован Flutter-проект `uGym Business` (`tj.ugym.business`), настроены строгие правила `analysis_options.yaml` и `AppConfig` (`dev`/`staging`/`prod`).
- **`B0-02`**: подключён пакет `ugym_core` (`path: ../ugym_core`, `D-002`; `D-003` на `material_ui: ^1.1.0`), реализованы `AppPreferences`, `ThemeController` (Light по умолчанию, Light/Dark/System) и `BusinessApiClient`.
- **`B0-03`**: реализованы RBAC (`BusinessRole`, `BusinessPermission`), `GymSummary`, `BusinessSessionController` (`bootstrapFromApi`, `isReadOnly` при `SUBSCRIPTION_EXPIRED`, выбор филиала с сохранением `gym_id` и `timezone`), виджеты `SubscriptionReadOnlyBanner`, `RoleGuard` и `GymBranchSelector`; добавлен `docs/api/platform.yaml` для эндпоинтов биллинга.
- Все проверки пройдены: `dart format` ✓, `flutter analyze` ✓ (`No issues found!`), `flutter test` ✓ (`11 passed`).

## Актуальное состояние окружения

- Flutter SDK `3.50.0` и Dart SDK `3.14.0` установлены; локальное тестирование и статический анализ работают полностью.
- Для сборки APK/запуска на телефоне позже понадобится Android SDK (`flutter doctor`).

## Точный следующий шаг

- Выполнить задачу **`B0-04`**: настроить локализацию `ru` / `tg` / `en`, реализовать адаптивный навигационный каркас (Bottom Navigation для `<600dp` и Navigation Rail для `>=600dp` с учётом `BusinessRole` и `SubscriptionReadOnlyBanner`) и проверку связи `GET /api/v1/health`, завершив этап `B0`.
