#!/bin/bash
set -euo pipefail
exec > /var/log/openclaw-setup.log 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing Node.js 24..."
curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
apt-get install -y nodejs

echo "==> Installing OpenClaw..."
npm install -g openclaw@latest

echo "==> Creating openclaw user..."
useradd -m -s /bin/bash openclaw

echo "==> Setting up OpenClaw config..."
mkdir -p /home/openclaw/.openclaw/workspace

cat > /home/openclaw/.openclaw/openclaw.json << 'OCEOF'
{
  "gateway": { "mode": "local" },
  "env": {
    "OPENAI_API_KEY": "PLACEHOLDER_OPENAI_KEY",
    "TELEGRAM_BOT_TOKEN": "PLACEHOLDER_TELEGRAM_TOKEN"
  },
  "logging": { "level": "info" },
  "agents": {
    "defaults": {
      "model": { "primary": "openai/gpt-4o" },
      "workspace": "/home/openclaw/.openclaw/workspace",
      "thinkingDefault": "off",
      "timeoutSeconds": 300,
      "heartbeat": { "every": "0m" },
      "skipBootstrap": true
    },
    "list": [{ "id": "morning-brief", "default": true }]
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": ["PLACEHOLDER_CHAT_ID"],
      "streaming": { "mode": "off" }
    }
  },
  "cron": { "enabled": true, "maxConcurrentRuns": 2 },
  "session": {
    "scope": "per-sender",
    "resetTriggers": ["/new", "/reset"],
    "reset": { "mode": "daily", "atHour": 4, "idleMinutes": 1440 }
  },
  "plugins": {
    "entries": {
      "duckduckgo": { "enabled": true }
    }
  }
}
OCEOF

cat > /home/openclaw/.openclaw/workspace/SOUL.md << 'SOULEOF'
# Morning Briefing Agent

You are a concise personal briefing assistant for a tech professional based in **Nagpur, India** (timezone: Asia/Kolkata).

## Persona

- Tone: crisp, informative, no fluff
- Format every briefing as a single Telegram-friendly message
- Use minimal emoji for section headers only
- Never exceed ~1500 characters per briefing
- Never use the & character in headings — use "and" instead

## Timezone

All times are in **IST (Asia/Kolkata, UTC+5:30)**. Today's date is always derived from the current system time.

## Briefing Structure

When asked to generate the morning briefing, produce exactly this layout:

```
Good morning! Here's your briefing for {date}.

---------------------------------------
WEATHER — Nagpur
{current temp, conditions, high/low for today, rain probability}

---------------------------------------
CALENDAR
{summary of today's events, or "No events scheduled" if empty}

---------------------------------------
AI and TECH HEADLINES
1. {headline + one-line summary}
2. {headline + one-line summary}
3. {headline + one-line summary}

---------------------------------------
Have a great day!
```

For afternoon and evening briefings, adjust the greeting:
- 12 PM: "Good afternoon! Here's your midday update for {date}."
- 6 PM: "Good evening! Here's your evening wrap-up for {date}."

## Rules

- Weather: search for "Nagpur weather today" — report temperature in Celsius
- AI news: search for "top AI news today" — pick the 3 most significant stories
- Calendar: if no calendar tool is connected, say "Calendar not connected — add Google Calendar tool to enable"
- If a search fails, note it gracefully ("Weather data unavailable") — never hallucinate data
- Keep the entire message scannable in under 30 seconds
SOULEOF

cat > /home/openclaw/.openclaw/workspace/HEARTBEAT.md << 'HBEOF'
# Heartbeat Checklist

This agent primarily runs via cron, not heartbeat.
HBEOF

cat > /home/openclaw/.openclaw/workspace/TOOLS.md << 'TOOLSEOF'
# Available Tools

## Web Search (DuckDuckGo)
Used to fetch real-time weather data and AI news headlines.

## File System
Read-only access to workspace files for configuration reference.
TOOLSEOF

chown -R openclaw:openclaw /home/openclaw/.openclaw

echo "==> Setting up gateway auth..."
sudo -u openclaw openclaw config set gateway.auth.mode token
sudo -u openclaw openclaw config set gateway.auth.token briefbot2026

echo "==> Creating systemd service..."
cat > /etc/systemd/system/openclaw-gateway.service << 'SVCEOF'
[Unit]
Description=OpenClaw Gateway - Morning Brief Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=openclaw
ExecStart=/usr/bin/openclaw gateway
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable openclaw-gateway
systemctl start openclaw-gateway

echo "==> Setup complete!"
