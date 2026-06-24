#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking prerequisites..."

# Node.js version check
if ! command -v node &> /dev/null; then
  echo "ERROR: Node.js not found. Install Node 24+ from https://nodejs.org"
  exit 1
fi

NODE_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 22 ]; then
  echo "ERROR: Node $NODE_MAJOR found — need Node 22.19+ (24 recommended)"
  exit 1
fi
echo "  Node.js $(node -v) OK"

# OpenClaw check
if ! command -v openclaw &> /dev/null; then
  echo "==> Installing OpenClaw..."
  npm install -g openclaw@latest
else
  echo "  OpenClaw $(openclaw --version 2>/dev/null || echo 'installed') OK"
fi

# Ollama check
if ! command -v ollama &> /dev/null; then
  echo "ERROR: Ollama not found. Install from https://ollama.com/download"
  exit 1
fi
echo "  Ollama $(ollama --version 2>/dev/null || echo 'installed') OK"

# Check for a model
if ! ollama list 2>/dev/null | grep -q "llama"; then
  echo "==> Pulling llama3.2 model..."
  ollama pull llama3.2
fi

# .env check
if [ ! -f .env ]; then
  echo "==> Creating .env from .env.example..."
  cp .env.example .env
  echo "  IMPORTANT: Edit .env with your TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID"
fi

# Copy workspace to ~/.openclaw
WORKSPACE_DIR="$HOME/.openclaw/workspace"
echo "==> Syncing workspace files to $WORKSPACE_DIR..."
mkdir -p "$WORKSPACE_DIR"
cp -v workspace/SOUL.md "$WORKSPACE_DIR/"
cp -v workspace/HEARTBEAT.md "$WORKSPACE_DIR/"
cp -v workspace/TOOLS.md "$WORKSPACE_DIR/"

# Copy config
echo "==> Copying openclaw.json to ~/.openclaw/..."
cp -v openclaw.json "$HOME/.openclaw/openclaw.json"

# Enable DuckDuckGo search
echo "==> Enabling DuckDuckGo search plugin..."
openclaw plugins enable duckduckgo 2>/dev/null || true

echo ""
echo "Setup complete! Next steps:"
echo "  1. Edit .env with your TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID"
echo "  2. Run: source .env && openclaw gateway"
echo "  3. Approve your Telegram pairing: openclaw pairing approve telegram <CODE>"
echo "  4. Add the cron job:"
echo '     openclaw cron create "30 7 * * *" \'
echo '       "Generate the morning briefing per SOUL.md instructions." \'
echo '       --name "morning-brief" \'
echo '       --tz "Asia/Kolkata" \'
echo '       --session isolated \'
echo '       --announce \'
echo '       --channel telegram \'
echo '       --to YOUR_TELEGRAM_CHAT_ID'
