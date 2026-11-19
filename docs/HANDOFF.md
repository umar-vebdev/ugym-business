# HANDOFF — uGym Business

**Текущий этап:** `B7` — Полная локализация модулей (`ru`/`tg`/`en`) и релизная сборка Android  
**Следующая задача:** `B7-04` — Настройка релизной подписи Android и проверка релизной сборки `APK`/`AAB`  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **Этапы `B0`–`B6`:** завершены полностью.
- **B7-01, B7-02, B7-03:** локализованы все экраны приложения (`ru`/`tg`/`en`, 380 ключей ARB, 100% паритет, 124 теста зелёные).

## Следующий шаг (`B7-04`)
1. Проверить `.gitignore` на защиту `android/key.properties`, `*.jks`, `*.keystore`.
2. Создать `android/key.properties.example` и настроить `signingConfigs.create("release")` в `android/app/build.gradle.kts` с безопасным fallback на `debug`, если `key.properties` отсутствует.
3. Добавить тест в `test/core/release_readiness_and_acceptance_test.dart` и проверить реальную сборку `flutter build apk --release --dart-define=FLAVOR=prod`.
