# Handoff — uGym Business (Business App)

**Обновлено:** 2026-11-16
**Текущий этап:** B0 — Фундамент проекта
**Текущая задача:** `B0-02` `[x]` завершена; следующая — `B0-03`

## Что сделано в последней сессии

- **`B0-01`**: инициализирован Flutter-проект `uGym Business` (`tj.ugym.business`), настроены строгие правила `analysis_options.yaml` и `AppConfig` (`dev`/`staging`/`prod`).
- **`B0-02`**: подключён пакет `ugym_core` (`path: ../ugym_core`, `D-002`; в `ugym_core` также выполнена миграция `D-003` на `material_ui: ^1.1.0`), реализованы `AppPreferences` поверх `TokenStorage`, `ThemeController` (Light по умолчанию, Light/Dark/System с сохранением), `BusinessApiClient` и подключение тем `UcraftTheme.light()` / `UcraftTheme.dark()` в `lib/main.dart`.
- Все проверки пройдены: `dart format` ✓, `flutter analyze` ✓ (`No issues found!`), `flutter test` ✓ (`4 passed`).

## Актуальное состояние окружения

- Flutter SDK `3.50.0` и Dart SDK `3.14.0` установлены; локальное тестирование и статический анализ работают полностью.
- Для сборки APK/запуска на телефоне позже понадобится Android SDK (`flutter doctor`).

## Точный следующий шаг

- Выполнить задачу **`B0-03`**: реализовать состояние/баннер режима чтения `SUBSCRIPTION_EXPIRED` (`is_read_only`), `RoleBootstrap` / `RoleGuard` для ролей `owner` / `admin` / `trainer` (по матрице прав из `uGym_Business_Mobile_TZ.md` п. 1) и контроллер локального переключения текущего филиала `gym_id` с unit- и widget-тестами.
