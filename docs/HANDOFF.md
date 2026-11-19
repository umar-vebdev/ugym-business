# HANDOFF — uGym Business

**Статус:** Этапы `B0`–`B7` полностью завершены (`format ✓`, `analyze ✓`, `test ✓` — **125 тестов**)  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **B0–B6:** полный функционал по ТЗ (`owner`/`admin`/`trainer`, RBAC, `SUBSCRIPTION_EXPIRED` read-only, идемпотентность, киоск QR + WakeLock + PIN, сканер QR, CRM, тарифы/абонементы, касса `PaymentMark`, расписание/тренеры, витрина + фотогалерея с `image_picker`, аналитика с графиками uCraft, офлайн-шрифты `Inter`/`GeistMono`, иконки `LucideIcons`, адаптивность `<600dp` / `600–839dp` / `>=840dp`).
- **B7-01, B7-02, B7-03:** полная локализация всех экранов приложения (`ru`/`tg`/`en`) через `BusinessStringsScope` и синхронизированные `app_{ru,tg,en}.arb` (**380 ключей**, 100% паритет).
- **B7-04:** настроена релизная подпись Android (`android/app/build.gradle.kts` читает `android/key.properties` с безопасным fallback на `debug`, добавлен шаблон `android/key.properties.example`, секреты `android/key.properties`, `*.jks`, `*.keystore` защищены в `.gitignore`).

## Что нужно для финальной сборки релиза
1. Установить Android SDK (`ANDROID_HOME=/home/umar/Android/Sdk`) или запустить в CI.
2. Скопировать `android/key.properties.example` → `android/key.properties`, указать keystore и выполнить:
   - `flutter build appbundle --release --dart-define=FLAVOR=prod` (для Google Play)
   - `flutter build apk --release --dart-define=FLAVOR=prod` (для прямой установки)
3. При необходимости отправить локальные коммиты в `origin/main` (`git push`) и аналогично в `../ugym_core`.
