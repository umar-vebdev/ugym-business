# HANDOFF — uGym Business

**Текущий этап:** `B4` — Полировка UX, Режим чтения, QA и Релиз  
**Текущая задача:** `B4-01` — аудит и тесты RBAC, доступа тренера и режима `SUBSCRIPTION_EXPIRED`  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- Этапы `B0` (`B0-01`–`B0-04`), `B1` (`B1-01`–`B1-06b`), `B2` (`B2-01`–`B2-07`) и `B3` (`B3-01`–`B3-08`) завершены полностью:
  - В задаче `B3-08` репозитории `RemoteTrainersScheduleRepository`, `RemoteStorefrontAndStaffRepository` и `RemoteAnalyticsAndBillingRepository` подключены в `lib/main.dart` (`UgymBusinessApp`) и `lib/core/router/business_shell.dart` (`BusinessShell`).
  - В `BusinessShell` подключены `AnalyticsScreen`, подвкладки `Расписание` (`ScheduleTab`) и `Тренеры` (`TrainersScreen`) в «Операциях» (для `trainer` сразу открывается `ScheduleTab`), а также подвкладки `Витрина`, `Штат`, `Рассылки` и `Подписка` в «Ещё» с фильтрацией по RBAC.
  - Добавлены интеграционные widget-тесты `test/features/schedule/shell_b3_integration_test.dart` для ролей `owner`, `admin` и `trainer`.
- Проверки: `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (No issues found), `flutter test` (83 passed).

## Точный следующий шаг
1. Начать `B4-01`: проверить `BusinessSessionController` и все экраны `B1`–`B3` на соответствие RBAC и реакции на `403 SUBSCRIPTION_EXPIRED` (включая аудит сценария входа тренера и выбора филиала для `ScheduleTab`).
2. Перевести `B4-01` в `[~]` в `docs/TASKS.md`, согласовать план с разработчиком и добавить недостающие тесты/правки.
