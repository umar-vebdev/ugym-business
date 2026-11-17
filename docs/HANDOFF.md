# HANDOFF — uGym Business

**Текущий этап:** `B2` — CRM клиентов, Абонементы и Касса (`PaymentMark`)  
**Текущая задача:** `B2-07` — карточка клиента 360° (`ClientDetailScreen`) и интеграция `B2` в `BusinessShell` / `UgymBusinessApp`  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- Этап `B0` (`B0-01`–`B0-04`) завершён: каркас `tj.ugym.business`, `AppConfig`, `BusinessApiClient`, `BusinessRole`, `BusinessSessionController`, `SubscriptionReadOnlyBanner`, `RoleGuard`, `GymBranchSelector`, `LocaleController`, `BusinessShell`.
- Этап `B1` (`B1-01`–`B1-06b`) завершён полностью:
  - Auth (`AuthRepository`, `AuthController`, `AuthFlowScreen`);
  - Company Onboarding, филиалы и валюта (`CompanyOnboardingCard`, `CompanyBranchesAndCurrencyCard`);
  - Kiosk QR 60с HMAC + PIN + WakeLock (`GymQrKioskScreen`);
  - Сканер QR клиента (`ScanClientQrScreen`, разрешения камеры в Android/iOS);
  - Журнал визитов, ручная отметка (в т.ч. задним числом с `Idempotency-Key`), отмена в окне 24 ч с причиной (`VisitsLogScreen`, `ManualCheckInSheet`) и интеграция экранов `B1` в `BusinessShell` / `UgymBusinessApp`.
- Проверки: `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (0 issues), `flutter test` (39 passed).

## Точный следующий шаг
1. Прочитать раздел `B2` в `uGym_Business_Mobile_TZ.md` и эндпоинты в `business-core.yaml`.
2. Раскрыть эпик `B2` в мелкие задачи в `docs/TASKS.md` и показать список разработчику для подтверждения.
