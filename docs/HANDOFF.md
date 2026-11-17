# Handoff — uGym Business (Business App)

**Обновлено:** 2026-11-17
**Текущий этап:** B1 — Авторизация, Онбординг, Киоск QR и Визиты
**Текущая задача:** `B1-01` `[x]` завершена; следующая — `B1-02`

## Что сделано в последней сессии

- Завершён этап **`B0`** (`B0-01`–`B0-04` `[x]`).
- Эпик **`B1`** раскрыт на задачи **`B1-01`–`B1-06`** в `docs/TASKS.md`.
- **`B1-01`**: реализованы `AuthenticatedUser`, `AuthRepository` (`features/auth/domain`) и `RemoteAuthRepository` (`features/auth/data`: `/auth/login` с записью токена, `/auth/register`, `/auth/send-otp`, `/auth/verify-email`, `/auth/reset-password`, `/auth/logout` с очисткой `TokenStorage`, `GET /user`), покрыты 5 новыми unit-тестами (`400`/`401`/`422`/`429`, офлайн-выход).
- Все проверки пройдены: `dart format` ✓, `flutter analyze` ✓ (`No issues found!`), `flutter test` ✓ (`18 passed`).

## Актуальное состояние окружения

- Flutter SDK `3.50.0` и Dart SDK `3.14.0` установлены; локальное тестирование и статический анализ работают полностью.
- Для сборки APK/запуска на телефоне позже понадобится Android SDK (`flutter doctor`).

## Точный следующий шаг

- Выполнить задачу **`B1-02`**: реализовать `AuthController` (автозапуск сессии/роли при наличии токена, вход, регистрация + Email OTP, сброс пароля и выход с очисткой хранилища) и UI-экраны (`LoginScreen`, `RegisterUserScreen`, `EmailOtpVerifyScreen`, `ResetPasswordScreen`) в стиле uCraft Design System 1.0 с widget-тестами.
