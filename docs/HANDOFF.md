# HANDOFF — uGym Business

**Текущий этап:** `B5` — Боевая готовность к реальному серверу и устройствам  
**Текущая задача:** Следующая — `B5-03` (Живые переходы из QR-сканера в кассу/клиентов и режим `isReadOnly` в кассе)  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **Этапы `B0`–`B4`:** полностью завершены (100 тестов).
- **`B5-01`:** окружения `--dart-define` (`AppConfig.fromEnvironment` / `AppConfig.resolve`) и автоопределение роли `trainer` (`D-005`).
- **`B5-02`:** живой дашборд «Обзор» (`OverviewDashboardView`) в `BusinessShell`: KPI дня для `owner`, операционные счётчики заявок `pending` и истекающих абонементов, быстрые кнопки ресепшна и навигация без обращения `admin` к `analytics/*`. Проверки: `format ✓`, `analyze ✓`, `test ✓` (108 тестов).

## Точный следующий шаг (`B5-03`)
1. В `ScanClientQrScreen` добавить опциональный переход к списку клиентов (`onOpenClients`) при отказах по абонементу (`NO_ACTIVE_MEMBERSHIP`, `MEMBERSHIP_FROZEN`, `DAILY_LIMIT_EXCEEDED`, `OUTSIDE_ALLOWED_TIME`) и подключить `onOpenPayments` (открытие `PosCheckoutScreen`) и `onOpenClients` (переход во вкладку «Клиенты») в `BusinessShell._openClientScanner`.
2. Передать `sessionController` (опционально) в `PosCheckoutScreen` для отображения `SubscriptionReadOnlyBanner` и блокировки кнопки «Провести продажу» при `isReadOnly`.
3. Добавить тесты на оба сценария, прогнать `format`/`analyze`/`test` и закоммитить `B5-03`.
