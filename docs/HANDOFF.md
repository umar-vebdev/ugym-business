# HANDOFF — uGym Business

**Текущий этап:** Все этапы (`B0`–`B6`) завершены ✓  
**Текущая задача:** Задачи этапов `B0`–`B6` выполнены полностью  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **Этапы `B0`–`B4`:** фундамент (`ugym_core`, uCraft 1.0, RBAC, `SUBSCRIPTION_EXPIRED`), аутентификация + онбординг + киоск QR + сканер QR + визиты, CRM + абонементы + касса `PaymentMark`, тренеры + расписание + витрина/фото + штат + аналитика/рассылки/подписка, E2E-тесты, `Retry-After` + `Idempotency-Key`, планшетные раскладки и iOS/Android релизные манифесты (100 тестов).
- **Этап `B5` (`B5-01`–`B5-04`):** окружения `--dart-define` (`FLAVOR`, `API_BASE_URL`, `ENABLE_KIOSK_MODE`), автоопределение роли `trainer` (`D-005`), живой дашборд `OverviewDashboardView`, переходы из `ScanClientQrScreen` в `PosCheckoutScreen` / «Клиенты», `isReadOnly` в кассе и загрузка/сжатие фото с устройства через `image_picker` (`D-006`) с превью (112 тестов).
- **Этап `B6` (`B6-01`–`B6-04b`):**
  - `B6-01`: графики `VisitsByDayBarChart` и `RevenuePaymentMixBar` в `AnalyticsScreen` по uCraft 1.0 §15 (сетка `border`, токены цветов, табличный `GeistMono`, `Semantics`, пустые состояния).
  - `B6-02a` / `B6-02b`: офлайн-шрифты `Inter` и `GeistMono` (`assets/fonts/` + `pubspec.yaml`, OFL) и полный перевод всего приложения на иконки **Lucide** (`lucide_icons_flutter`, `D-007`) с автопроверкой отсутствия `Icons.*` в `lib/`.
  - `B6-03` / `B6-04a` / `B6-04b`: внедрён `BusinessStringsScope` (`InheritedWidget`) через `MaterialApp.builder` и `BusinessShell`, словари `app_{ru,tg,en}.arb` расширены до 167 ключей (100% паритет), локализованы оболочка, баннеры/гварды, «Обзор», авторизация, сканер QR, киоск QR, касса, аналитика, графики, рассылки и подписка.
- **Итоговые проверки:** `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (No issues found), `flutter test` (121 passed).

## Следующие возможные шаги перед публикацией
1. Настроить релизную подпись Android (`signingConfig` через `key.properties` в `android/app/build.gradle.kts`) и проверить сборку `APK`/`AAB` (`flutter build appbundle --dart-define=FLAVOR=prod`).
2. При необходимости доперевести оставшиеся формы CRM, расписания, витрины и штата на `tg`/`en` (инфраструктура `BusinessStringsScope` уже готова).
3. Опубликовать локальные коммиты в `origin/main` (и `../ugym_core`) и провести ручную приёмку на физических устройствах iOS/iPad и Android со стендом `staging`/`prod`.
