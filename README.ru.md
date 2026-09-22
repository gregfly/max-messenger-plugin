<p align="center">
  <h1 align="center">MAX Messenger Plugin для Claude Code</h1>
  <p align="center">
    Подключение ИИ-агентов Claude Code к <a href="https://max.ru">мессенджеру MAX</a> (VK) через Bot API
  </p>
  <p align="center">
    <a href="#возможности">Возможности</a> &bull;
    <a href="#быстрый-старт">Быстрый старт</a> &bull;
    <a href="#инструменты">Инструменты</a> &bull;
    <a href="#управление-доступом">Доступ</a> &bull;
    <a href="README.md">English Documentation</a>
  </p>
</p>

---

MCP-плагин канала, который связывает Bot API [мессенджера MAX](https://max.ru) с сессиями [Claude Code](https://claude.ai/code). Отправляйте сообщения, получайте ответы, делитесь файлами — всё через систему каналов Claude Code.

## Возможности

- **Сообщения в реальном времени** — получение через long-poll с мгновенной доставкой
- **Отправка и приём** — полноценный обмен текстовыми сообщениями с поддержкой Markdown
- **Редактирование сообщений** — обновление без push-уведомлений (идеально для статусов)
- **Обмен файлами** — загрузка и отправка файлов до 50 МБ (картинки отображаются inline)
- **Реакции эмодзи** — реакция на сообщение эмодзи (отправляется как quote-ответ; нативных реакций у MAX нет)
- **Проброс разрешений** — одобрение запросов разрешений Claude Code прямо из чата (`y <код>` / `n <код>`)
- **Авто-разбивка** — длинные сообщения автоматически делятся по 4000 символов
- **Управление доступом** — безопасно по умолчанию (`allowlist`); доступны режимы `open` и `disabled`
- **Индикатор набора** — показывает «печатает...» пока агент работает
- **Корректное завершение** — чистое отключение при выходе
- **Мультиагентность** — несколько агентов с разными ботами и конфигами

## Быстрый старт

### 1. Создайте бота MAX

- Зайдите на [MAX Business](https://business.max.ru)
- Создайте бота и получите подтверждение
- Скопируйте токен бота из раздела **Интеграция**

### 2. Установка

```bash
git clone https://github.com/gregfly/max-messenger-plugin.git
cd max-messenger-plugin
chmod +x install.sh
./install.sh
```

Установщик:
- Скопирует плагин в `~/.claude/plugins/local/max-messenger/`
- Создаст директории для конфигурации
- Запросит токен бота
- Установит зависимости (нужен [Bun](https://bun.sh))

### 3. Запуск Claude Code с каналом

```bash
claude --dangerously-load-development-channels server:max-messenger
```

## Ручная установка

```bash
# Копирование плагина
mkdir -p ~/.claude/plugins/local/max-messenger
cp -r . ~/.claude/plugins/local/max-messenger/

# Конфигурация
mkdir -p ~/.claude/channels/max
echo "MAX_BOT_TOKEN=ваш_токен" > ~/.claude/channels/max/.env
chmod 600 ~/.claude/channels/max/.env

# Управление доступом
# Безопасно по умолчанию: allowlist. Впишите СВОЙ user_id в allowFrom — при
# пустом списке не принимается никто. (user_id виден в meta входящего сообщения.)
cat > ~/.claude/channels/max/access.json << 'EOF'
{
  "dmPolicy": "allowlist",
  "allowFrom": ["ВАШ_MAX_USER_ID"],
  "groups": {}
}
EOF

# Установка зависимостей
cd ~/.claude/plugins/local/max-messenger
bun install
```

## Инструменты

Плагин предоставляет четыре MCP-инструмента для Claude Code:

| Инструмент | Описание |
|------------|----------|
| `reply` | Отправить ответ в чат MAX. Поддерживает текст до 4000 символов (авто-разбивка). Передайте `chat_id` из входящего сообщения. |
| `react` | Реакция на сообщение эмодзи. Отправляется как quote-ответ с эмодзи — нативных реакций у MAX нет. |
| `edit_message` | Редактирование отправленного сообщения. Без push-уведомления — идеально для обновления статуса. |
| `send_file` | Отправка файла (абсолютный путь, макс. 50 МБ). Картинки отображаются inline. |

## Проброс разрешений

Когда Claude Code запрашивает разрешение на инструмент, запрос форвардится всем пользователям из allowlist как `🔐 Разрешение: <инструмент>` с коротким кодом. Одобрить — ответ **`y <код>`**, запретить — **`n <код>`**. Решать могут только пользователи из allowlist, и такой ответ трактуется как решение (в сессию как обычное сообщение он НЕ доставляется).

## Переменные окружения

| Переменная | Обязательна | Описание |
|------------|-------------|----------|
| `MAX_BOT_TOKEN` | Да | Токен бота из MAX Business |
| `MAX_STATE_DIR` | Нет | Путь к конфигурации (по умолчанию: `~/.claude/channels/max`) |
| `MAX_API_BASE` | Нет | Базовый URL API (по умолчанию: `https://platform-api.max.ru`) |

## Управление доступом

Настройте `~/.claude/channels/max/access.json`:

```json
{
  "dmPolicy": "allowlist",
  "allowFrom": ["user_id_1", "user_id_2"],
  "groups": {
    "-group_chat_id": {
      "allowFrom": ["user_id_1"]
    }
  }
}
```

### Режимы доступа в личных сообщениях

| Режим | Поведение |
|-------|-----------|
| `allowlist` | **(по умолчанию)** Только от указанных user ID — безопасно по умолчанию. Без `access.json` не принимается никто, пока не добавите свой `user_id`. |
| `open` | Принимать сообщения от всех |
| `disabled` | Отклонять все сообщения |

## Мультиагентная настройка

Запускайте несколько агентов с отдельными конфигурациями через `MAX_STATE_DIR`:

```bash
# Агент 1
export MAX_STATE_DIR=~/.claude-agent1/channels/max
claude --dangerously-load-development-channels server:max-messenger

# Агент 2
export MAX_STATE_DIR=~/.claude-agent2/channels/max
claude --dangerously-load-development-channels server:max-messenger
```

Каждому агенту нужен свой токен бота и `access.json` в своей директории.

## Требования

- [Bun](https://bun.sh) v1.0+
- [Claude Code](https://claude.ai/code) v2.1+

## Лицензия

MIT — см. [LICENSE](LICENSE)
