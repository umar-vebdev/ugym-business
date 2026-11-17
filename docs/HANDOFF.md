# Handoff — uGym Business (Business App)

**Обновлено:** 2026-11-17
**Текущий этап:** B1 — Авторизация, Онбординг, Киоск QR и Визиты
**Текущая задача:** `B1-03` `[x]` завершена; следующая — `B1-04`

## Что сделано в последней сессии

- Завершён этап **`B0`** (`B0-01`–`B0-04` `[x]`), эпик **`B1`** декомпозирован на `B1-01`–`B1-06`.
- **`B1-01`**: реализованы `AuthenticatedUser`, `AuthRepository` и `RemoteAuthRepository` (`login`, `register`, `send-otp`, `verify-email`, `reset-password`, `logout`, `GET /user`).
- **`B1-02`**: реализованы `AuthController` и `AuthFlowScreen` (вход по email/телефону, регистрация + Email OTP, сброс пароля, выход) с интеграцией в `UgymBusinessApp` и `BusinessShell`.
- **`B1-03`**: реализованы `CompanyOnboardingRepository` + `RemoteCompanyOnboardingRepository`, форма онбординга `CompanyOnboardingCard` (`POST /business/companies`, перевод `noCompany` → `owner`) и панель `CompanyBranchesAndCurrencyCard` (создание/правка филиалов, геозона `50..5000` м, смена валюты).
- Все проверки пройдены: `dart format` ✓, `flutter analyze` ✓ (`No issues found!`), `flutter test` ✓ (`24 passed`).

## Актуальное состояние окружения

- Flutter SDK `3.50.0` и Dart SDK `3.14.0` установлены; локальное тестирование и статический анализ работают полностью.
- Для сборки APK/запуска на телефоне позже понадобится Android SDK (`flutter doctor`).

## Точный следующий шаг

- Выполнить задачу **`B1-04`**: реализовать доменные модели (`GymQrPayload`, `CheckInResult`, `VisitRecord`), контракт `ReceptionVisitsRepository` и `RemoteReceptionVisitsRepository` (`/business/gyms/{id}/qr`, `/check-in-qr` с `Idempotency-Key`, `/visits`, `/clients/{id}/visits`, `/visits/{id}/cancel`) с unit-тестами.
