# HANDOFF — uGym Business

**Текущий этап:** `B8` — Переход на **uCraft Design System 1.1**  
**Текущая задача:** `B8-05` — Применение v1.1 к расписанию, витрине, штату, аналитике, рассылкам и подписке + пересборка Wi-Fi APK  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **B8-01 – B8-04b:** документация v1.1, общие компоненты v1.1 в `../ugym_core`, `BusinessShell`, `OverviewDashboardView`, CRM клиентов, журнал визитов, тарифы/истекающие, заявки/продажи и касса/товары переведены на v1.1 (`126` тестов зелёные).

## Следующий шаг (`B8-05`)
1. Перевести `trainers_screen.dart`, `schedule_tab.dart`, `storefront_editor_screen.dart`, `staff_management_screen.dart`, `analytics_and_billing_screens.dart` на v1.1.
2. Прогнать `dart format`, `flutter analyze`, `flutter test`, зафиксировать `B8-05` и пересобрать Wi-Fi debug APK (`http://192.168.2.99:8000/api/v1`).
