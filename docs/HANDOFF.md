# HANDOFF — uGym Business

**Текущий этап:** `B5` — Боевая готовность к реальному серверу и устройствам  
**Текущая задача:** Следующая — `B5-02` (Живой дашборд «Обзор» для `owner` и `admin`)  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **Этапы `B0`–`B4`:** полностью завершены (100 тестов).
- **`B5-01`:** добавлены `AppConfig.fromEnvironment()` / `AppConfig.resolve(...)` (`FLAVOR`, `API_BASE_URL`, `ENABLE_KIOSK_MODE`), подключены в `lib/main.dart` и `BusinessShell`, а в `BusinessSessionController.bootstrapFromApi` реализовано автоматическое определение роли `trainer` через пробу `GET /business/schedule/sessions/1/bookings` (`D-005`). Проверки: `format ✓`, `analyze ✓`, `test ✓` (105 тестов).

## Точный следующий шаг (`B5-02`)
1. Создать виджет `OverviewDashboardView` в `lib/features/analytics_billing/presentation/overview_dashboard_view.dart` (KPI выручки/визитов за сегодня для `owner`, счётчики заявок `pending` и истекающих абонементов, быстрые действия ресепшна и переходы к разделам, состояния `loading`/`content`/`error` и блокировка мутаций при `isReadOnly`).
2. Подключить `OverviewDashboardView` во вкладке `BusinessDestination.overview` внутри `lib/core/router/business_shell.dart`.
3. Добавить тесты для `owner`, `admin` и `isReadOnly`, прогнать `format`/`analyze`/`test` и закоммитить `B5-02`.
