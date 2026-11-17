# Handoff — uGym Business (Business App)

**Обновлено:** 2026-11-17
**Текущий этап:** B1 — Авторизация, Онбординг, Киоск QR и Визиты
**Текущая задача:** `B1-06a` `[x]` завершена; следующая — `B1-06b`

## Что сделано в последней сессии

- **`B1-01`–`B1-04`**: домен и репозитории Auth, CompanyOnboarding, Reception/Visits; UI входа, OTP, сброса пароля, онбординга компании, филиалов и валюты.
- **`B1-05`**: киоск QR зала (`GymQrKioskScreen`, `KioskPinGuard` со SHA-256 + соль, `KioskWakeLock`), зависимости `crypto`, `qr_flutter`, `wakelock_plus` (`D-003`).
- **`B1-06a`** (задача `B1-06` разбита на `a`/`b`): `mobile_scanner` (`D-004`), `QrScannerBuilder`, `ReceptionScanController` (пауза сканера, повтор с тем же `Idempotency-Key` при сбое сети) и `ScanClientQrScreen` (карточка успеха, крупные экраны отказа для кодов `422`).
- Все проверки пройдены: `dart format` ✓, `flutter analyze` ✓ (`No issues found!`), `flutter test` ✓ (`35 passed`).

## Актуальное состояние окружения

- Flutter SDK `3.50.0` и Dart SDK `3.14.0` установлены; локальное тестирование и статический анализ работают полностью.
- Для сборки APK/запуска на телефоне позже понадобится Android SDK (`flutter doctor`).
- Для `mobile_scanner` на реальном устройстве нужны разрешения камеры: `NSCameraUsageDescription` (iOS `Info.plist`) и `android.permission.CAMERA` (`AndroidManifest.xml`) — добавить в `B1-06b` или `B4`.

## Точный следующий шаг

- Выполнить **`B1-06b`**: `VisitsLogScreen` (журнал `GET /business/visits`, отмена в пределах 24 ч с обязательной причиной), `ManualCheckInSheet` (ручной визит с `visited_at` задним числом и `Idempotency-Key`) и подключение сканера, киоска и журнала в `BusinessShell` (вкладка «Операции») с учётом ролей.
