# HANDOFF — uGym Business

**Текущий этап:** `B4` — Полировка UX, Режим чтения, QA и Релиз  
**Текущая задача:** `B4-04` — релизная подготовка iOS/Android и итоговый приёмочный чек-лист  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- Этапы `B0`–`B3` и задачи `B4-01`, `B4-02`, `B4-03` завершены полностью:
  - В `B4-03` в `BusinessShell` поддержан брейкпоинт `>=840dp` (`NavigationRail(extended: true)` и `maxWidth: 1040`).
  - В `GymQrKioskScreen` добавлена двухколоночная альбомная раскладка при ширине `>=840dp`.
  - В `lib/l10n/app_{ru,tg,en}.arb` и `BusinessStrings` синхронизированы все ключи, а `SubscriptionReadOnlyBanner` и кнопка «Выйти» переведены через `BusinessStrings`.
  - Добавлены 5 тестов в `test/core/responsive_theme_and_l10n_test.dart`.
- Проверки: `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (No issues found), `flutter test` (97 passed).

## Точный следующий шаг
1. Начать `B4-04`: проверить `ios/Runner/Info.plist`, `PrivacyInfo.xcprivacy`, `android/app/src/main/AndroidManifest.xml`, отсутствие IAP и внешних ссылок оплаты, а также пройти итоговый приёмочный чек-лист (п. 7.2 ТЗ).
2. Перевести `B4-04` в `[~]` в `docs/TASKS.md` и согласовать план с разработчиком.
