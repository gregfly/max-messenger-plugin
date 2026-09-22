<p align="center">
  <h1 align="center">MAX Messenger Plugin for Claude Code</h1>
  <p align="center">
    Connect Claude Code AI agents to <a href="https://max.ru">MAX Messenger</a> (VK) via Bot API
  </p>
  <p align="center">
    <a href="#features">Features</a> &bull;
    <a href="#quick-start">Quick Start</a> &bull;
    <a href="#tools">Tools</a> &bull;
    <a href="#access-control">Access Control</a> &bull;
    <a href="README.ru.md">Документация на русском</a>
  </p>
</p>

---

MCP channel plugin that bridges [MAX Messenger](https://max.ru) Bot API to [Claude Code](https://claude.ai/code) sessions. Send messages, receive replies, share files — all through Claude Code's channel system.

## Features

- **Real-time messaging** — long-poll based message receiving with instant delivery
- **Send & receive** — full text messaging with Markdown support
- **Edit messages** — update sent messages without push notifications (perfect for progress updates)
- **File sharing** — upload and send files up to 50 MB (images display inline)
- **Emoji reactions** — react to a message with an emoji (posted as a quote-reply; MAX has no native reactions)
- **Permission relay** — approve Claude Code tool-permission prompts right from the chat (`y <code>` / `n <code>`)
- **Auto-chunking** — long messages automatically split at 4000 char limit
- **Access control** — secure by default (`allowlist`); `open` and `disabled` modes available
- **Typing indicator** — shows "typing..." while agent processes
- **Graceful shutdown** — clean disconnect on exit
- **Multi-agent** — run multiple agents with separate bot tokens and configs

## Quick Start

### 1. Create a MAX bot

- Go to [MAX Business](https://business.max.ru)
- Create a bot and get it approved
- Copy the bot token from the **Integration** section

### 2. Install

```bash
git clone https://github.com/gregfly/max-messenger-plugin.git
cd max-messenger-plugin
chmod +x install.sh
./install.sh
```

The installer will:
- Copy the plugin to `~/.claude/plugins/local/max-messenger/`
- Create config directories
- Ask for your bot token
- Install dependencies (requires [Bun](https://bun.sh))

### 3. Run Claude Code with the channel

The installer registers the `max-messenger` MCP server **project-scoped** in `~/max-channel/.mcp.json`, so launch from that directory:

```bash
cd ~/max-channel && claude --dangerously-load-development-channels server:max-messenger
```

On first run Claude Code asks you to approve the project-scoped `max-messenger` server — confirm it. It is registered per-directory rather than globally on purpose: MAX allows one `/updates` consumer per bot token, so a global entry would make every new `claude` session spawn a competing poller and steal the channel.

## Manual Installation

```bash
# Copy plugin
mkdir -p ~/.claude/plugins/local/max-messenger
cp -r . ~/.claude/plugins/local/max-messenger/

# Create config
mkdir -p ~/.claude/channels/max
echo "MAX_BOT_TOKEN=your_token_here" > ~/.claude/channels/max/.env
chmod 600 ~/.claude/channels/max/.env

# Create access control
# Secure by default: allowlist. Put YOUR MAX user_id in allowFrom — with an
# empty list nobody is accepted. (Find your user_id in an inbound message's meta.)
cat > ~/.claude/channels/max/access.json << 'EOF'
{
  "dmPolicy": "allowlist",
  "allowFrom": ["YOUR_MAX_USER_ID"]
}
EOF

# Install dependencies
cd ~/.claude/plugins/local/max-messenger
bun install

# Register the MCP server (project-scoped). Without this step Claude Code does
# not know a server named "max-messenger" and the channel flag starts nothing.
mkdir -p ~/max-channel
cat > ~/max-channel/.mcp.json << EOF
{
  "mcpServers": {
    "max-messenger": {
      "command": "bun",
      "args": ["run", "--cwd", "$HOME/.claude/plugins/local/max-messenger", "--shell=bun", "--silent", "start"]
    }
  }
}
EOF
```

## Tools

The plugin exposes four MCP tools to Claude Code:

| Tool | Description |
|------|-------------|
| `reply` | Send a reply to a MAX chat. Supports text up to 4000 chars (auto-chunked). Pass `chat_id` from inbound message. |
| `react` | React to a message with an emoji. Posted as an emoji quote-reply — MAX has no native reaction API. |
| `edit_message` | Edit a previously sent message. Edits don't trigger push notifications — ideal for progress updates. |
| `send_file` | Send a file attachment (absolute path, max 50 MB). Images render inline. |

## Permission Relay

When Claude Code asks for permission to run a tool, the prompt is forwarded to every allowlisted user as `🔐 Разрешение: <tool>` followed by a short code. Approve by replying **`y <code>`** or deny with **`n <code>`**. Only allowlisted users can decide, and such a reply is consumed as the decision (it is not delivered into the session as a normal message).

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MAX_BOT_TOKEN` | Yes | Bot token from MAX Business |
| `MAX_STATE_DIR` | No | Config directory (default: `~/.claude/channels/max`) |
| `MAX_API_BASE` | No | API base URL (default: `https://platform-api.max.ru`) |

## Access Control

Configure `~/.claude/channels/max/access.json`:

```json
{
  "dmPolicy": "allowlist",
  "allowFrom": ["user_id_1", "user_id_2"]
}
```

### DM Policy Options

| Policy | Behavior |
|--------|----------|
| `allowlist` | **(default)** Only from listed user IDs — secure by default. With no `access.json`, nobody is accepted until you add your `user_id`. |
| `open` | Accept messages from everyone |
| `disabled` | Reject all DMs |

### Group Chats

There is no per-group configuration: access is decided by the sender, not the chat. A message from a group reaches the session only if its author is in `allowFrom`; everyone else is silently ignored. Replies go to whatever chat the message came from (the `chat_id` in its meta) — there is no separate outbound chat filter. A `groups` key left in an older `access.json` is ignored.

## Multi-Agent Setup

Run multiple agents with separate configs by setting `MAX_STATE_DIR`:

```bash
# Agent 1
export MAX_STATE_DIR=~/.claude-agent1/channels/max
claude --dangerously-load-development-channels server:max-messenger

# Agent 2
export MAX_STATE_DIR=~/.claude-agent2/channels/max
claude --dangerously-load-development-channels server:max-messenger
```

Each agent needs its own bot token and `access.json` in its state directory.

## MAX Bot API Reference

- **Base URL:** `https://platform-api.max.ru`
- **Documentation:** [dev.max.ru/docs-api](https://dev.max.ru/docs-api)
- **Rate limit:** 30 requests/second
- **Auth:** `Authorization: <token>` header

## Requirements

- [Bun](https://bun.sh) v1.0+ runtime
- [Claude Code](https://claude.ai/code) v2.1+

## License

MIT — see [LICENSE](LICENSE)
