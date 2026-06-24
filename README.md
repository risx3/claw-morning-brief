# Claw Morning Brief

Telegram daily briefing bot powered by [OpenClaw](https://github.com/openclaw/openclaw). A scheduled cron job fires every morning at 7:30 AM IST and delivers a personal digest — Nagpur weather, calendar summary, and top 3 AI headlines — straight to your Telegram.

Zero coding required. Pure config and prompt engineering via `SOUL.md`.

## Tech Stack

| Component                      | Role                               |
| ------------------------------ | ---------------------------------- |
| **OpenClaw Gateway**           | Agent runtime and scheduler        |
| **Telegram** (grammY adapter)  | Message delivery channel           |
| **Cron scheduler**             | Triggers briefing at 7:30 AM daily |
| **DuckDuckGo search**          | Fetches live weather and AI news   |
| **Ollama (Llama 3.2)**         | Local LLM for formatting briefing  |

## How It Works

```text
1. Cron fires at 7:30 AM IST daily
2. Gateway triggers the briefing agent in an isolated session
3. Agent calls DuckDuckGo search for Nagpur weather + AI news
4. Ollama (local LLM) formats everything into a clean message
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
- **Ollama** with a model pulled
- **Telegram bot** created via BotFather
- **Cloudflare WARP** (if Telegram is blocked on your network)
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

### 3. Install Ollama

**macOS:**

```bash
brew install ollama
```

**Linux:**

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Windows:**

Download from [ollama.com/download](https://ollama.com/download).

Then pull a model:

```bash
ollama pull llama3.2
```

Verify Ollama is running:

```bash
ollama list
```

### 4. Create a Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Choose a name (e.g. "Morning Brief") and a username (e.g. `morning_brief_bot`)
4. BotFather replies with a **bot token** — copy it (format: `123456789:ABCdefGHI...`)
5. **Find your user ID** — message [@userinfobot](https://t.me/userinfobot) and note the numeric `Id`

Save both values; you'll need them during setup.

### 5. Install Cloudflare WARP (if needed)

Only required if Telegram API is blocked on your network (common with some ISPs in India).

```bash
brew install --cask cloudflare-warp
```

Open Cloudflare WARP from Launchpad, accept the privacy policy, and toggle the connection ON.

### 6. Install uv (Optional)

Only needed if you plan to add Python utility scripts to the project.

**macOS / Linux:**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows:**

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
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

#### 1. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
OLLAMA_BASE_URL=http://localhost:11434
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=your-numeric-user-id
```

#### 2. Deploy workspace files

```bash
# Copy workspace to OpenClaw's config directory
mkdir -p ~/.openclaw/workspace
cp workspace/SOUL.md ~/.openclaw/workspace/
cp workspace/HEARTBEAT.md ~/.openclaw/workspace/
cp workspace/TOOLS.md ~/.openclaw/workspace/

# Copy gateway config
cp openclaw.json ~/.openclaw/openclaw.json
```

#### 3. Enable DuckDuckGo search plugin

```bash
openclaw plugins enable duckduckgo
```

#### 4. Start the gateway

```bash
source .env
openclaw gateway
```

#### 5. Approve Telegram pairing

In another terminal:

```bash
# Message your bot on Telegram, then approve the pairing
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

#### 6. Add the morning cron job

```bash
openclaw cron create "30 7 * * *" \
  "Generate the morning briefing per SOUL.md instructions." \
  --name "morning-brief" \
  --tz "Asia/Kolkata" \
  --session isolated \
  --announce \
  --channel telegram \
  --to YOUR_TELEGRAM_CHAT_ID
```

#### 7. Verify

```bash
# Test the cron job immediately
openclaw cron run morning-brief --wait

# Check cron job status
openclaw cron list
```

## Running as a Daemon

Install OpenClaw as a persistent background service so it survives reboots:

```bash
openclaw onboard --install-daemon

# Verify it's running
openclaw gateway status
```

This installs a `launchd` (macOS) or `systemd` (Linux) user service that auto-starts on boot.

**Note:** Your Mac needs to be awake when the cron fires. To schedule an automatic wake:

```bash
sudo pmset repeat wakeorpoweron MTWRFSU 07:25:00
```

## Customization

### Change briefing time

```bash
openclaw cron remove morning-brief
openclaw cron create "0 8 * * *" \
  "Generate the morning briefing per SOUL.md instructions." \
  --name "morning-brief" \
  --tz "Asia/Kolkata" \
  --session isolated \
  --announce \
  --channel telegram \
  --to YOUR_TELEGRAM_CHAT_ID
```

### Change city

Edit `workspace/SOUL.md` and replace "Nagpur" with your city. Re-copy to `~/.openclaw/workspace/`.

### Use a different Ollama model

```bash
ollama pull llama3.1:8b
```

Update `openclaw.json`:

```json
"model": { "primary": "ollama/llama3.1:8b" }
```

### Use a cloud LLM instead

Update `openclaw.json` with one of:

```json
"model": { "primary": "google/gemini-2.5-flash" }
"model": { "primary": "openrouter/meta-llama/llama-3.3-70b-instruct:free" }
```

Set the corresponding API key (`GOOGLE_API_KEY` or `OPENROUTER_API_KEY`) in your `.env`.

### Add Google Calendar

Enable the Google Calendar tool in OpenClaw and the agent will automatically include today's events (the `SOUL.md` prompt already handles this).

## Troubleshooting

| Problem              | Fix                                                                        |
| -------------------- | -------------------------------------------------------------------------- |
| Bot doesn't respond  | `openclaw pairing list telegram` — approve pending pairings                |
| Cron doesn't fire    | `openclaw cron list` — check job status and timezone                       |
| Weather data missing | Ensure DuckDuckGo plugin is enabled: `openclaw plugins enable duckduckgo`  |
| Telegram times out   | Install Cloudflare WARP: `brew install --cask cloudflare-warp`             |
| Ollama not found     | Ensure Ollama is running: `ollama serve`                                   |
| Gateway won't start  | Run `openclaw doctor --fix`                                                |

## License

MIT
