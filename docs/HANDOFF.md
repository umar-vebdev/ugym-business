# HANDOFF — uGym Business

**Текущий этап:** `B4` — Полировка UX, Режим чтения, QA и Релиз  
**Текущая задача:** `B4-03` — адаптивность iPad/tablet, Light/Dark темы, ARB-локализация и состояния экранов  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- Этапы `B0`–`B3` и задачи `B4-01`, `B4-02` завершены полностью:
  - В `B4-02` в `ugym_core` добавлен парсинг `Retry-After` и флаг `isRateLimited` в `UgymApiException` (`429 TOO_MANY_REQUESTS`).
  - В `ReceptionScanController` и `ScanClientQrScreen` сохраняется `Idempotency-Key` при `429`, `5xx` и обрывах сети с отображением `Retry-After`.
  - В `MembershipRequestsQueueTab` ключи `Idempotency-Key` сохраняются на уровне вкладки для пары `(request_id, payment_method)` даже при закрытии/повторном открытии диалога оплаты.
  - В `GymQrKioskScreen` при сбое обновления QR текущий код остаётся на экране с предупреждением и восстанавливается на следующем тике.
  - Добавлены 5 тестов в `test/core/network_resilience_and_idempotency_test.dart`.
- Проверки: `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (No issues found), `flutter test` (92 passed; в `ugym_core`: 34 passed).

## Точный следующий шаг
1. Начать `B4-03`: проверить планшетную раскладку (`>=600dp`, `>=840dp`), Light/Dark темы, локализацию `ru`/`tg`/`en` (в т.ч. ARB и длинные строки) и состояния `loading`/`empty`/`error`/`permission-denied`.
2. Перевести `B4-03` в `[~]` в `docs/TASKS.md`, согласовать план с разработчиком и добавить тесты.
