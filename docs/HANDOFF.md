# HANDOFF — uGym Business

**Текущий этап:** Все этапы (`B0`–`B5`) завершены ✓  
**Текущая задача:** Задачи этапов `B0`–`B5` выполнены полностью  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **Этап `B0` (`B0-01`–`B0-04`):** инициализация `tj.ugym.business`, подключение `ugym_core` (uCraft Design System 1.0 Midnight & Cobalt), RBAC (`owner`/`admin`/`trainer`/`noCompany`), перехват `SUBSCRIPTION_EXPIRED`, ARB-словари `ru`/`tg`/`en`, адаптивный `BusinessShell`.
- **Этап `B1` (`B1-01`–`B1-06b`):** аутентификация (Email/Телефон, OTP, сброс пароля), онбординг компании (14-дневный триал), филиалы и геозона, киоск QR зала (`60с`, WakeLock, PIN), сканер QR клиента, журнал визитов, ручной чекин и отмена за 24 ч.
- **Этап `B2` (`B2-01`–`B2-07`):** CRM клиентов, карточка 360°, слияние дублей, конструктор тарифов, заморозка/отмена абонементов, касса `PaymentMark`, очередь заявок, история продаж, возвраты и склад товаров.
- **Этап `B3` (`B3-01`–`B3-08`):** тренеры, шаблоны и генерация расписания (до 62 дней), отмена с возвратом визитов, записи группы, витрина и до 10 фото, штат по email, аналитика, рассылки `push`/`sms` и статус подписки платформы.
- **Этап `B4` (`B4-01`–`B4-04`):** E2E-проверки RBAC и `SUBSCRIPTION_EXPIRED`, `429 Retry-After` и `Idempotency-Key`, планшетные раскладки (`>=600dp`, `>=840dp`), релизные манифесты iOS (`Info.plist`, `PrivacyInfo.xcprivacy`) и Android (`AndroidManifest.xml`), отсутствие IAP.
- **Этап `B5` (`B5-01`–`B5-04`):**
  - `B5-01`: окружения `--dart-define` (`FLAVOR`, `API_BASE_URL`, `ENABLE_KIOSK_MODE`) и автоматическое определение роли `trainer` через пробу `GET /business/schedule/sessions/1/bookings` (`D-005`).
  - `B5-02`: живой дашборд «Обзор» (`OverviewDashboardView`) — KPI дня для `owner`, счётчики заявок `pending` и истекающих абонементов, быстрые действия и переходы без обращения `admin` к `analytics/*`.
  - `B5-03`: живые переходы из `ScanClientQrScreen` в `PosCheckoutScreen` («Принять оплату») и во вкладку «Клиенты» («Открыть клиентов») с освобождением камеры, а также `SubscriptionReadOnlyBanner` и блокировка продаж в `PosCheckoutScreen` при `isReadOnly`.
  - `B5-04`: выбор и нативное сжатие фото витрины с устройства через `image_picker` (`D-006`, `1920x1920`, `quality: 85`), подключение в `BusinessShell`, превью в `GymPhotosManager` и обработка отказа доступа к галерее.
- **Итоговые проверки:** `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (No issues found), `flutter test` (112 passed).

## Следующие возможные направления
1. **Локализация и дизайн uCraft 1.0 (`B6`):** перевести экраны модулей на `ru`/`tg`/`en`, добавить график посещаемости по дням в `AnalyticsScreen`, подключить шрифты `Inter` / `Geist Mono` и иконки `Lucide`.
2. **Сборка и публикация:** настроить релизную подпись Android (`signingConfig`), проверить сборку под `staging`/`prod` (`flutter build apk --dart-define=FLAVOR=prod`), запушить коммиты в `origin/main` и провести ручную приёмку на физических iOS/iPad и Android устройствах.
