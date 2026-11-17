# Handoff — uGym Business (Business App)

**Обновлено:** 2026-11-17
**Текущий этап:** B1 — Авторизация, Онбординг, Киоск QR и Визиты
**Текущая задача:** `B1-02` `[x]` завершена; следующая — `B1-03`

## Что сделано в последней сессии

- Завершён этап **`B0`** (`B0-01`–`B0-04` `[x]`), эпик **`B1`** декомпозирован на `B1-01`–`B1-06`.
- **`B1-01`**: реализованы `AuthenticatedUser`, `AuthRepository` и `RemoteAuthRepository` (`login`, `register`, `send-otp`, `verify-email`, `reset-password`, `logout`, `GET /user`).
- **`B1-02`**: реализованы `AuthController` (авторизация по email/телефону, восстановление сессии `tryRestoreSession`, регистрация + Email OTP, сброс пароля, выход со сбросом роли) и `AuthFlowScreen` в стиле uCraft 1.0, подключённые к `UgymBusinessApp` и `BusinessShell`.
- Все проверки пройдены: `dart format` ✓, `flutter analyze` ✓ (`No issues found!`), `flutter test` ✓ (`21 passed`).

## Актуальное состояние окружения

- Flutter SDK `3.50.0` и Dart SDK `3.14.0` установлены; локальное тестирование и статический анализ работают полностью.
- Для сборки APK/запуска на телефоне позже понадобится Android SDK (`flutter doctor`).

## Точный следующий шаг

- Выполнить задачу **`B1-03`**: реализовать онбординг новой компании (`POST /business/companies` для `noCompany` → `owner`), управление филиалами (`POST/PATCH /business/gyms`, геозона `50..5000` м) и смену валюты компании (`GET /business/currencies`, `PATCH /business/company/currency`) с unit- и widget-тестами.
