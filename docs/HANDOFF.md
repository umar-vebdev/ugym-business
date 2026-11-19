# HANDOFF — uGym Business

**Текущий этап:** `B6` — Локализация (`ru`/`tg`/`en`) и полировка по uCraft Design System 1.0  
**Текущая задача:** Следующая — `B6-04b` (Локализация кассы, аналитики, графиков, рассылок и подписки)  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **Этапы `B0`–`B5`:** полностью завершены (112 тестов).
- **`B6-01`:** добавлены графики `VisitsByDayBarChart` и `RevenuePaymentMixBar` в `AnalyticsScreen`.
- **`B6-02a` / `B6-02b`:** подключены офлайн-шрифты `Inter` и `GeistMono` (`assets/fonts/` + `pubspec.yaml`, OFL), все иконки переведены на `LucideIcons.*` (`D-007`).
- **`B6-03`:** внедрён `BusinessStringsScope`, переведены `BusinessShell`, `RoleGuard`, `SubscriptionReadOnlyBanner`, `GymBranchSelector` и `OverviewDashboardView`.
- **`B6-04a`:** переведены `AuthFlowScreen`, `ScanClientQrScreen` и `GymQrKioskScreen` на `ru`/`tg`/`en` с синхронизацией `app_{ru,tg,en}.arb`. Проверки: `format ✓`, `analyze ✓`, `test ✓` (120 тестов).

## Точный следующий шаг (`B6-04b`)
1. Расширить `BusinessStrings` и синхронно обновить `app_ru.arb`, `app_tg.arb`, `app_en.arb` ключами для кассы, аналитики, графиков, рассылок и подписки.
2. Перевести `PosCheckoutScreen`, `AnalyticsScreen`, `VisitsByDayBarChart`, `RevenuePaymentMixBar`, `AnnouncementsScreen` и `BillingStatusScreen` через `BusinessStringsScope.of(context)`.
3. Добавить тесты на локализацию в `tg` и `en`, прогнать `format`/`analyze`/`test`, закоммитить `B6-04b` и закрыть этап `B6`.
