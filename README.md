# Claw Morning Brief

Telegram daily briefing bot powered by [OpenClaw](https://github.com/openclaw/openclaw). A scheduled cron job fires every morning at 7:30 AM IST and delivers a personal digest — Nagpur weather, calendar summary, and top 3 AI headlines — straight to your Telegram.

Zero coding required. Pure config and prompt engineering via `SOUL.md`.

## Tech Stack

| Component                      | Role                               |
| ------------------------------ | ---------------------------------- |
| **OpenClaw Gateway**           | Agent runtime and scheduler        |
| **Telegram** (grammY adapter)  | Message delivery channel           |
| **Cron scheduler**             | Triggers briefing at 7:30 AM daily |
| **Web search tool**            | Fetches live weather and AI news   |
| **Groq (Llama 3.3 70B)**       | LLM for formatting the briefing    |

## How It Works

```text
1. Cron fires at 7:30 AM IST daily
2. Gateway triggers the briefing agent in an isolated session
3. Agent calls web search for Nagpur weather + AI news
4. LLM formats everything into a clean Telegram message
5. Gateway delivers the message to your Telegram
```

## Project Structure

```text
claw-morning-brief/
├── openclaw.json           # Gateway + agent + cron + Telegram config
├── workspace/
│   ├── SOUL.md             # Agent persona and briefing prompt
│   ├── HEARTBEAT.md        # Fallback heartbeat checklist
│   └── TOOLS.md            # Available tools reference
├── scripts/
│   └── setup.sh            # One-command setup script
├── .env.example            # Environment variable template
├── .gitignore
├── pyproject.toml          # Project metadata
└── README.md
```

## Prerequisites

- **Node.js 24+** (or 22.19+)
- **OpenClaw** installed globally
- **Telegram bot** created via BotFather
- **Google AI API key** (Gemini Pro)
- **uv** (optional) — Python project tooling

### 1. Install Node.js

**macOS (Homebrew):**

```bash
brew install node
node -v   # should print v24.x or v22.19+
```

**Linux (Ubuntu/Debian):**

```bash
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v
```

**Windows:**

Download the installer from [nodejs.org](https://nodejs.org) and run it, or use winget:

```bash
winget install OpenJS.NodeJS.LTS
```

### 2. Install OpenClaw

```bash
npm install -g openclaw@latest

# Verify
openclaw --version

# Run health check
openclaw doctor
```

### 3. Create a Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Choose a name (e.g. "Morning Brief") and a username (e.g. `morning_brief_bot`)
4. BotFather replies with a **bot token** — copy it (format: `123456789:ABCdefGHI...`)
5. **Find your user ID** — message [@userinfobot](https://t.me/userinfobot) and note the numeric `Id`

Save both values; you'll need them during setup.

### 4. Get a Groq API Key

1. Go to [console.groq.com](https://console.groq.com)
2. Sign up (free, no credit card required)
3. Go to **API Keys** → **Create API Key**
4. Copy the key (format: `gsk_...`)

Groq's free tier includes 1000+ requests/day with ultra-fast inference on Llama 3.3 70B.

### 5. Install uv (Optional)

Only needed if you plan to add Python utility scripts to the project.

**macOS / Linux:**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows:**

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Verify:

```bash
uv --version
```

## Installation

### Quick Start

```bash
git clone https://github.com/rishabh/claw-morning-brief.git
cd claw-morning-brief

# Run the setup script
./scripts/setup.sh
```

### Manual Setup

#### 1. Install OpenClaw

```bash
npm install -g openclaw@latest

# Verify installation
openclaw --version
openclaw doctor
```

#### 2. Create your Telegram bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy the bot token (format: `123456789:ABCdefGHI...`)
4. Find your Telegram user ID — message [@userinfobot](https://t.me/userinfobot) and note the `Id` field

#### 3. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
GROQ_API_KEY=gsk_your-key-here
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=your-numeric-user-id
```

#### 4. Deploy workspace files

```bash
# Copy workspace to OpenClaw's config directory
mkdir -p ~/.openclaw/workspace
cp workspace/SOUL.md ~/.openclaw/workspace/
cp workspace/HEARTBEAT.md ~/.openclaw/workspace/
cp workspace/TOOLS.md ~/.openclaw/workspace/

# Copy gateway config
cp openclaw.json ~/.openclaw/openclaw.json
```

#### 5. Start the gateway

```bash
source .env
openclaw gateway
```

#### 6. Approve Telegram pairing

In another terminal:

```bash
# Message your bot on Telegram, then approve the pairing
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

#### 7. Add the morning cron job

```bash
openclaw cron create "30 7 * * *" \
  "Generate the morning briefing per SOUL.md instructions." \
  --name "morning-brief" \
  --tz "Asia/Kolkata" \
  --session isolated \
  --announce \
  --channel telegram
```

#### 8. Verify

```bash
# Test the cron job immediately
openclaw cron run morning-brief --wait

# Check cron job status
openclaw cron list
```

## Using uv (Optional)

If you want to manage the project metadata or add Python utility scripts:

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Initialize virtual environment
uv venv
source .venv/bin/activate

# Sync dependencies (none required for base setup)
uv sync
```

## Deployment

### Option A: Daemon Mode (Recommended)

Install OpenClaw as a persistent background service:

```bash
openclaw onboard --install-daemon

# Verify it's running
openclaw gateway status
```

This installs a `launchd` (macOS) or `systemd` (Linux) user service that auto-starts on boot.

### Option B: Docker

```bash
# Pull and run with your config mounted
docker run -d \
  --name morning-brief \
  --restart unless-stopped \
  -v ~/.openclaw:/root/.openclaw \
  -e GROQ_API_KEY \
  -e TELEGRAM_BOT_TOKEN \
  -e TELEGRAM_CHAT_ID \
  openclaw/openclaw:latest gateway
```

### Option C: VPS / Cloud VM

```bash
# On your server
npm install -g openclaw@latest
openclaw onboard --install-daemon

# Copy your config
scp -r ~/.openclaw/openclaw.json user@server:~/.openclaw/
scp -r workspace/ user@server:~/.openclaw/workspace/

# Set env vars in the service file or use .env
openclaw gateway status
```

### Keeping It Running

```bash
# Check gateway health
openclaw doctor

# View logs
openclaw logs --follow

# Restart after config changes
openclaw gateway restart
```

## Customization

### Change briefing time

```bash
# Remove old job and create new one
openclaw cron remove morning-brief
openclaw cron create "0 8 * * *" \
  "Generate the morning briefing per SOUL.md instructions." \
  --name "morning-brief" \
  --tz "Asia/Kolkata" \
  --session isolated \
  --announce \
  --channel telegram
```

### Change city

Edit `workspace/SOUL.md` and replace "Nagpur" with your city. Re-copy to `~/.openclaw/workspace/`.

### Use Gemini instead of Groq

Update `openclaw.json`:

```json
"model": { "primary": "google/gemini-2.5-flash" }
```

Set `GOOGLE_API_KEY=AIza...` in your `.env`.

### Use Ollama (local, offline)

Update `openclaw.json`:

```json
"model": { "primary": "ollama/llama3.3" }
```

Set `OLLAMA_BASE_URL=http://localhost:11434` in your `.env`.

### Add Google Calendar

Enable the Google Calendar tool in OpenClaw and the agent will automatically include today's events (the `SOUL.md` prompt already handles this).

## Troubleshooting

| Problem              | Fix                                                          |
| -------------------- | ------------------------------------------------------------ |
| Bot doesn't respond  | `openclaw pairing list telegram` — approve pending pairings  |
| Cron doesn't fire    | `openclaw cron list` — check job status and timezone         |
| Weather data missing | Web search tool may be rate-limited — check `openclaw logs`  |
| 401 on Telegram      | Verify `TELEGRAM_BOT_TOKEN` is correct                       |
| Gateway won't start  | Run `openclaw doctor --fix`                                  |

## License

MIT
