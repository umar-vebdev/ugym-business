# HANDOFF — uGym Business

**Текущий этап:** Все этапы (`B0`–`B4`) завершены  
**Текущая задача:** Задачи дорожной карты `B0`–`B4` выполнены полностью  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **Этап `B0` (`B0-01`–`B0-04`):** инициализация `tj.ugym.business`, подключение `ugym_core` (uCraft Design System 1.0 Midnight & Cobalt), RBAC (`owner`/`admin`/`trainer`/`noCompany`), перехват `SUBSCRIPTION_EXPIRED`, ARB-словари `ru`/`tg`/`en`, адаптивный `BusinessShell`.
- **Этап `B1` (`B1-01`–`B1-06b`):** аутентификация (Email/Телефон, OTP, сброс пароля), онбординг компании (14-дневный триал), филиалы и геозона, киоск QR зала (`60с`, WakeLock, PIN), сканер QR клиента, журнал визитов, ручной чекин и отмена за 24 ч.
- **Этап `B2` (`B2-01`–`B2-07`):** CRM клиентов, карточка 360°, слияние дублей, конструктор тарифов, заморозка/отмена абонементов, касса `PaymentMark`, очередь заявок, история продаж, возвраты и склад товаров.
- **Этап `B3` (`B3-01`–`B3-08`):** тренеры, шаблоны и генерация расписания (до 62 дней), отмена с возвратом визитов, записи группы, витрина и до 10 фото, штат по email, аналитика, рассылки `push`/`sms` и статус подписки платформы.
- **Этап `B4` (`B4-01`–`B4-04`):** E2E-проверки RBAC и `SUBSCRIPTION_EXPIRED`, поддержка `429 Retry-After` и устойчивость `Idempotency-Key`, планшетные раскладки (`>=600dp`, `>=840dp`) и синхронизация ARB, а также релизная конфигурация iOS (`Info.plist`, `PrivacyInfo.xcprivacy`) и Android (`AndroidManifest.xml`), отсутствие IAP и приёмочные тесты.
- **Итоговые проверки:** `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (No issues found), `flutter test` (100 passed).

## Следующие шаги перед публикацией в магазины
1. Настроить релизные ключи подписи Android (`signingConfig`) и профили Apple Developer / TestFlight, а также убедиться в Xcode, что `ios/Runner/PrivacyInfo.xcprivacy` включён в `Copy Bundle Resources`.
2. Подключить реальный стенд `staging` / `prod` и провести ручную приёмку на физических устройствах iOS/iPad и Android с камерой и реальной сетью.
