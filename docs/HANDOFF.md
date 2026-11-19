# HANDOFF — uGym Business

**Текущий этап:** `B6` — Локализация (`ru`/`tg`/`en`) и полировка по uCraft Design System 1.0  
**Текущая задача:** Следующая — `B6-04a` (Локализация `AuthFlowScreen`, `ScanClientQrScreen`, `GymQrKioskScreen`)  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **Этапы `B0`–`B5`:** полностью завершены (112 тестов).
- **`B6-01`:** добавлены графики `VisitsByDayBarChart` и `RevenuePaymentMixBar` в `AnalyticsScreen`.
- **`B6-02a` / `B6-02b`:** подключены офлайн-шрифты `Inter` и `GeistMono` (`assets/fonts/` + `pubspec.yaml`, OFL), все иконки переведены на `LucideIcons.*` (`D-007`).
- **`B6-03`:** внедрён `BusinessStringsScope` в `UgymBusinessApp` и `BusinessShell`, расширены и синхронизированы `app_{ru,tg,en}.arb`, переведены оболочка, баннер/гварды и дашборд «Обзор». Проверки: `format ✓`, `analyze ✓`, `test ✓` (119 тестов).

## Точный следующий шаг (`B6-04a`)
1. Расширить `BusinessStrings` и синхронно обновить `app_ru.arb`, `app_tg.arb`, `app_en.arb` ключами для авторизации, сканера QR клиента и киоска QR зала.
2. Перевести `AuthFlowScreen`, `ScanClientQrScreen` и `GymQrKioskScreen` через `BusinessStringsScope.of(context)`.
3. Добавить тесты на локализацию этих экранов в `tg` и `en`, прогнать `format`/`analyze`/`test` и закоммитить `B6-04a`.
