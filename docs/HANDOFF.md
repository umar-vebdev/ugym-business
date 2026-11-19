# HANDOFF — uGym Business

**Текущий этап:** `B5` — Боевая готовность к реальному серверу и устройствам  
**Текущая задача:** Следующая — `B5-04` (Выбор/сжатие фото витрины с устройства `image_picker` и превью в `GymPhotosManager`)  
**Репозиторий:** `/home/umar/ugym-mobile/uGym Business` (`main`)

## Что сделано
- **Этапы `B0`–`B4`:** полностью завершены (100 тестов).
- **`B5-01`:** окружения `--dart-define` (`AppConfig.fromEnvironment` / `AppConfig.resolve`) и автоопределение роли `trainer` (`D-005`).
- **`B5-02`:** живой дашборд «Обзор» (`OverviewDashboardView`) для `owner` и `admin`.
- **`B5-03`:** живые переходы из `ScanClientQrScreen` в `PosCheckoutScreen` («Принять оплату») и во вкладку «Клиенты» («Открыть клиентов») с освобождением камеры, а также `SubscriptionReadOnlyBanner` и блокировка продаж в `PosCheckoutScreen` при `isReadOnly`. Проверки: `format ✓`, `analyze ✓`, `test ✓` (110 тестов).

## Точный следующий шаг (`B5-04`)
1. Добавить пакет `image_picker` в `pubspec.yaml` и зафиксировать решение `D-006` в `docs/DECISIONS.md`.
2. Реализовать `pickGymPhotoFromGallery` в `lib/features/storefront_staff/presentation/gym_photo_picker.dart` (нативное сжатие `maxWidth: 1920`, `maxHeight: 1920`, `imageQuality: 85`), подключить в `BusinessShell` (с инъекцией для тестов) и добавить превью загруженных фотографий в `GymPhotosManager`.
3. Добавить тесты, прогнать `format`/`analyze`/`test`, закрыть `B5-04` и этап `B5`.
