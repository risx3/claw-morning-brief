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
  "logging": { "level": "info" },
  "agents": {
    "defaults": {
      "model": { "primary": "google/gemini-2.5-pro" },
      "workspace": "/home/openclaw/.openclaw/workspace",
      "thinkingDefault": "medium",
      "timeoutSeconds": 300,
      "heartbeat": { "every": "0m" },
      "skipBootstrap": true
    },
    "list": [
      {
        "id": "morning-brief",
        "default": true
      }
    ]
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": ["YOUR_CHAT_ID"],
      "streaming": { "mode": "off" }
    }
  },
  "cron": {
    "enabled": true,
    "maxConcurrentRuns": 2
  },
  "session": {
    "scope": "per-sender",
    "resetTriggers": ["/new", "/reset"],
    "reset": {
      "mode": "daily",
      "atHour": 4,
      "idleMinutes": 1440
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
AI & TECH HEADLINES
1. {headline + one-line summary}
2. {headline + one-line summary}
3. {headline + one-line summary}

---------------------------------------
Have a great day!
```

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
If heartbeat is enabled, use this as a fallback.

- If it's between 7:00 AM and 7:45 AM IST and no briefing was sent today, generate and send the morning briefing.
- Otherwise, reply HEARTBEAT_OK.
HBEOF

cat > /home/openclaw/.openclaw/workspace/TOOLS.md << 'TOOLSEOF'
# Available Tools

## Web Search
Used to fetch real-time weather data and AI news headlines.
The agent has access to web search by default via the OpenClaw gateway.

## File System
Read-only access to workspace files for configuration reference.
TOOLSEOF

cat > /home/openclaw/.env << 'ENVEOF'
GOOGLE_API_KEY=YOUR_GOOGLE_API_KEY
TELEGRAM_BOT_TOKEN=YOUR_TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=YOUR_CHAT_ID
TZ=Asia/Kolkata
ENVEOF

chown -R openclaw:openclaw /home/openclaw/.openclaw /home/openclaw/.env

echo "==> Creating systemd service..."
cat > /etc/systemd/system/openclaw-gateway.service << 'SVCEOF'
[Unit]
Description=OpenClaw Gateway - Morning Brief Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=openclaw
EnvironmentFile=/home/openclaw/.env
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
