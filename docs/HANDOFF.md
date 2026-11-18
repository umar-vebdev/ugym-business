# HANDOFF — uGym Business

**Текущий этап:** `B4` — Полировка UX, Режим чтения, QA и Релиз  
**Текущая задача:** `B4-02` — сетевая устойчивость и строгая идемпотентность (`Idempotency-Key`, `429 Retry-After`)  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- Этапы `B0` (`B0-01`–`B0-04`), `B1` (`B1-01`–`B1-06b`), `B2` (`B2-01`–`B2-07`) и `B3` (`B3-01`–`B3-08`) завершены полностью.
- В задаче `B4-01`:
  - В `SubscriptionReadOnlyBanner` добавлена кнопка `'Подробнее'`, открывающая `BillingStatusScreen` в `BusinessShell`.
  - В `ClientDetailScreen` добавлен `ListenableBuilder` на `sessionController` и `SubscriptionReadOnlyBanner` для мгновенной блокировки мутаций при `403 SUBSCRIPTION_EXPIRED`.
  - Для роли `trainer` реализовано восстановление сохранённого филиала в `BusinessSessionController.bootstrapFromApi` и быстрый поиск списка группы по `ID занятия` в `ScheduleTab` (без синхронного `setState` в `initState`).
  - Добавлены E2E-тесты `test/core/rbac_and_read_only_e2e_test.dart`.
- Проверки: `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (No issues found), `flutter test` (87 passed).

## Точный следующий шаг
1. Начать `B4-02`: провести аудит сохранения `Idempotency-Key` при ретраях (`PosCheckoutScreen`, `MembershipRequestsQueueTab`, `ManualCheckInSheet`, `ReceptionScanController`) и обработки `429 TOO_MANY_REQUESTS` (`Retry-After`) и потери сети.
2. Перевести `B4-02` в `[~]` в `docs/TASKS.md`, согласовать план и добавить тесты.
