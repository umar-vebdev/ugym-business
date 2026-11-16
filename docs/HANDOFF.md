# Handoff — uGym Business (Business App)

**Обновлено:** 2026-11-16
**Текущий этап:** B0 — Фундамент проекта
**Текущая задача:** B0-01 (ожидает установки Flutter SDK и Android SDK)

## Что сделано в последней сессии

- Создан отдельный каталог и заготовка репозитория **uGym Business** (`/home/umar/ugym-mobile/uGym Business`).
- Перенесены спецификации:
  - `docs/specs/uGym_Business_Mobile_TZ.md`
  - `docs/specs/uCraft_Design_System.md`
  - OpenAPI-контракты бэкенда `docs/api/*.yaml` (10 файлов)
- Настроены шаблоны управления разработкой с ИИ-агентом: `AGENTS.md`, `docs/TASKS.md`, `docs/HANDOFF.md`, `docs/DECISIONS.md`.

## Актуальное состояние окружения

- Flutter SDK / Dart SDK — не установлены (`which flutter` пуст).
- Android SDK / `adb` — не установлены.
- `java` — установлена (`/usr/bin/java`).
- Сборка iOS на текущей Linux-машине недоступна (потребуется macOS + Xcode или облачный CI позже).

## Точный следующий шаг

1. Установить Flutter SDK и Android SDK на Linux-машину разработчика и выполнить `flutter doctor`.
2. Инициализировать git-репозиторий (`git init`) и выполнить задачу **B0-01** (создание Flutter-проекта `tj.ugym.business` и каркаса `Feature-First`).
