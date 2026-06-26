# Claw Morning Brief

Telegram daily briefing bot powered by [OpenClaw](https://github.com/openclaw/openclaw). Scheduled cron jobs fire at **7:30 AM**, **12:00 PM**, and **6:00 PM IST** delivering a personal digest — Nagpur weather, calendar summary, and top 3 AI headlines — straight to your Telegram.

Zero coding required. Pure config and prompt engineering via `SOUL.md`.

## Tech Stack

| Component                      | Role                               |
| ------------------------------ | ---------------------------------- |
| **OpenClaw Gateway**           | Agent runtime and scheduler        |
| **Telegram** (grammY adapter)  | Message delivery channel           |
| **Cron scheduler**             | Triggers briefings 3x daily        |
| **DuckDuckGo search**          | Fetches live weather and AI news   |
| **OpenAI GPT-5.4 Mini**        | LLM for formatting the briefing    |
| **AWS EC2** (t4g.micro)        | Always-on cloud hosting            |

## How It Works

```text
1. Cron fires at 7:30 AM / 12:00 PM / 6:00 PM IST
2. Gateway triggers the briefing agent in an isolated session
3. Agent calls DuckDuckGo search for Nagpur weather + AI news
4. OpenAI GPT formats everything into a clean message
5. Gateway delivers the message to your Telegram
```

## Project Structure

```text
claw-morning-brief/
├── openclaw.json           # Gateway + agent + Telegram config
├── workspace/
│   ├── SOUL.md             # Agent persona and briefing prompt
│   ├── HEARTBEAT.md        # Fallback heartbeat checklist
│   └── TOOLS.md            # Available tools reference
├── scripts/
│   ├── setup.sh            # Local setup script
│   └── ec2-userdata.sh     # AWS EC2 deployment script
├── .env.example            # Environment variable template
├── .gitignore
├── pyproject.toml          # Project metadata
└── README.md
```

## Prerequisites

- **Node.js 24+** (or 22.19+)
- **OpenClaw** installed globally
- **OpenAI API key**
- **Telegram bot** created via BotFather
- **AWS account** (for cloud deployment)

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

### 2. Install OpenClaw

```bash
npm install -g openclaw@latest
openclaw --version
openclaw doctor
```

### 3. Create a Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Choose a name (e.g. "Morning Brief") and a username (e.g. `morning_brief_bot`)
4. BotFather replies with a **bot token** — copy it (format: `123456789:ABCdefGHI...`)
5. **Find your user ID** — message [@userinfobot](https://t.me/userinfobot) and note the numeric `Id`

### 4. Get an OpenAI API Key

1. Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create a new secret key
3. Copy the key (format: `sk-proj-...`)

### 5. Install AWS CLI

```bash
brew install awscli
aws configure
```

## Deployment (AWS EC2)

### 1. Clone and configure

```bash
git clone https://github.com/risx3/claw-morning-brief.git
cd claw-morning-brief
cp .env.example .env
# Edit .env with your OPENAI_API_KEY, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
```

### 2. Launch EC2 instance

```bash
# Create key pair
aws ec2 create-key-pair --key-name claw-morning-brief \
  --query 'KeyMaterial' --output text > ~/.ssh/claw-morning-brief.pem
chmod 400 ~/.ssh/claw-morning-brief.pem

# Create security group
SG_ID=$(aws ec2 create-security-group --group-name claw-brief-sg \
  --description "OpenClaw bot" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

# Get Ubuntu ARM64 AMI
AMI_ID=$(aws ec2 describe-images --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

# Launch instance
# First edit scripts/ec2-userdata.sh — replace PLACEHOLDER values with your actual keys
aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t4g.micro \
  --key-name claw-morning-brief \
  --security-group-ids $SG_ID \
  --user-data file://scripts/ec2-userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=claw-morning-brief}]'
```

### 3. Add cron jobs (after setup completes)

SSH into the instance and create 3 scheduled briefings:

```bash
ssh -i ~/.ssh/claw-morning-brief.pem ubuntu@<INSTANCE_IP>

# Set auth token
export OPENCLAW_TOKEN=briefbot2026

# 7:30 AM IST — Morning briefing
openclaw cron create "30 2 * * *" \
  "Generate the morning briefing per SOUL.md instructions." \
  --name morning-brief --tz Asia/Kolkata \
  --session isolated --announce --channel telegram --to YOUR_CHAT_ID

# 12:00 PM IST — Midday update
openclaw cron create "30 6 * * *" \
  "Generate the midday briefing per SOUL.md instructions. Use the afternoon greeting." \
  --name noon-brief --tz Asia/Kolkata \
  --session isolated --announce --channel telegram --to YOUR_CHAT_ID

# 6:00 PM IST — Evening wrap-up
openclaw cron create "30 12 * * *" \
  "Generate the evening briefing per SOUL.md instructions. Use the evening greeting." \
  --name evening-brief --tz Asia/Kolkata \
  --session isolated --announce --channel telegram --to YOUR_CHAT_ID

# Verify
openclaw cron list
```

### 4. Test

```bash
openclaw cron run morning-brief --wait
```

## Customization

### Change briefing times

```bash
openclaw cron remove morning-brief
openclaw cron create "0 3 * * *" \
  "Generate the morning briefing per SOUL.md instructions." \
  --name morning-brief --tz Asia/Kolkata \
  --session isolated --announce --channel telegram --to YOUR_CHAT_ID
```

### Change city

Edit `workspace/SOUL.md` and replace "Nagpur" with your city. Re-deploy to the instance.

### Use a different model

```bash
openclaw models set openai/gpt-5.4
# or
openclaw models set openai/gpt-5.5
```

### Add Google Calendar

Enable the Google Calendar tool in OpenClaw and the agent will automatically include today's events (the `SOUL.md` prompt already handles this).

## Troubleshooting

| Problem              | Fix                                                                       |
| -------------------- | ------------------------------------------------------------------------- |
| Bot doesn't respond  | `openclaw pairing list telegram` — approve pending pairings               |
| Cron doesn't fire    | `openclaw cron list` — check job status and timezone                      |
| Weather data missing | Ensure DuckDuckGo plugin is enabled: `openclaw plugins enable duckduckgo` |
| 401 on Telegram      | Verify `TELEGRAM_BOT_TOKEN` is correct                                    |
| Gateway won't start  | Run `openclaw doctor --fix`                                               |
| SSH times out        | Reboot instance: `aws ec2 reboot-instances --instance-ids <ID>`           |

## License

MIT
