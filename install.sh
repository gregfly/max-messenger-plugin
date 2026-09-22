#!/bin/bash
# Установка MAX Messenger плагина для Claude Code
# Запускать из папки с плагином

set -e

PLUGIN_DIR="$HOME/.claude/plugins/local/max-messenger"
STATE_DIR="$HOME/.claude/channels/max"
ENV_FILE="$STATE_DIR/.env"
ACCESS_FILE="$STATE_DIR/access.json"

echo "=== MAX Messenger Plugin для Claude Code ==="
echo ""

# 1. Копируем плагин
echo "1. Устанавливаю плагин..."
mkdir -p "$PLUGIN_DIR"
cp -f server.ts package.json .mcp.json "$PLUGIN_DIR/" 2>/dev/null || true
[ -f README.md ] && cp -f README.md "$PLUGIN_DIR/"
echo "   -> $PLUGIN_DIR"

# 2. Создаём директорию состояния
echo "2. Создаю директории..."
mkdir -p "$STATE_DIR/inbox"
chmod 700 "$STATE_DIR"

# 3. Токен бота
if [ -f "$ENV_FILE" ]; then
  echo "3. Токен уже настроен: $ENV_FILE"
else
  echo "3. Введите токен бота MAX (из https://business.max.ru):"
  read -r TOKEN
  if [ -z "$TOKEN" ]; then
    echo "   Токен не указан. Создайте файл вручную:"
    echo "   echo 'MAX_BOT_TOKEN=ваш_токен' > $ENV_FILE"
  else
    echo "MAX_BOT_TOKEN=$TOKEN" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "   -> Сохранено в $ENV_FILE"
  fi
fi

# 4. access.json
if [ -f "$ACCESS_FILE" ]; then
  echo "4. access.json уже существует"
else
  cat > "$ACCESS_FILE" << 'EOF'
{
  "dmPolicy": "allowlist",
  "allowFrom": ["ВАШ_MAX_USER_ID"]
}
EOF
  chmod 600 "$ACCESS_FILE"
  echo "4. Создан access.json (dmPolicy: allowlist) — впишите свой user_id в allowFrom"
fi

# 5. Устанавливаем зависимости
echo "5. Устанавливаю зависимости..."
cd "$PLUGIN_DIR"
bun install --no-summary 2>/dev/null || echo "   bun install не удался — установите bun: curl -fsSL https://bun.sh/install | bash"

# 6. Проверяем сборку
echo "6. Проверяю сборку..."
if bun build --target=bun server.ts --outdir /tmp/max-check 2>/dev/null; then
  rm -rf /tmp/max-check
  echo "   -> OK"
else
  echo "   -> Ошибка сборки. Проверьте зависимости."
fi

# 7. Регистрируем MCP-сервер. Именно этого шага не хватало: без регистрации
# claude не знает сервер "max-messenger", и флаг канала ничего не запускает.
# Регистрация project-scoped (отдельная директория запуска), а НЕ глобально в
# ~/.claude.json — нарочно: MAX даёт один consumer /updates на токен бота, и
# глобальная запись заставила бы КАЖДУЮ новую сессию claude поднимать свой
# поллер и перехватывать канал.
LAUNCH_DIR="$HOME/max-channel"
echo "7. Регистрирую MCP-сервер в $LAUNCH_DIR/.mcp.json..."
mkdir -p "$LAUNCH_DIR"
cat > "$LAUNCH_DIR/.mcp.json" << EOF
{
  "mcpServers": {
    "max-messenger": {
      "command": "bun",
      "args": ["run", "--cwd", "$PLUGIN_DIR", "--shell=bun", "--silent", "start"]
    }
  }
}
EOF
echo "   -> $LAUNCH_DIR/.mcp.json"

echo ""
echo "=== Готово! ==="
echo ""
echo "Запуск (из директории канала, чтобы подхватился .mcp.json):"
echo "  cd $LAUNCH_DIR && claude --dangerously-load-development-channels server:max-messenger"
echo ""
echo "При первом запуске claude попросит одобрить project-scoped сервер max-messenger — подтвердите."
echo "Впишите свой MAX user_id в $ACCESS_FILE (allowFrom), иначе сообщения будут отброшены."
echo ""
