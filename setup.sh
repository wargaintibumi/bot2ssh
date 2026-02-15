#!/bin/bash

# ============================================
# bot2ssh Setup Script
# ============================================

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  bot2ssh - Ngrok SSH Monitor Setup"
echo "========================================"
echo ""

# ---- Step 1: Check dependencies ----
echo -e "${YELLOW}[1/5] Checking dependencies...${NC}"

MISSING=0

if ! command -v ngrok &> /dev/null; then
    echo -e "${RED}  ✗ ngrok not found${NC}"
    echo ""
    echo "  Install ngrok:"
    echo "    wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-$(dpkg --print-architecture 2>/dev/null || echo amd64).tgz"
    echo "    tar xvzf ngrok-v3-stable-linux-*.tgz"
    echo "    sudo mv ngrok /usr/local/bin/"
    echo ""
    MISSING=1
else
    echo -e "${GREEN}  ✓ ngrok $(ngrok version 2>/dev/null | head -1)${NC}"
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}  ✗ curl not found (install: sudo apt install curl)${NC}"
    MISSING=1
else
    echo -e "${GREEN}  ✓ curl installed${NC}"
fi

if ! command -v screen &> /dev/null; then
    echo -e "${YELLOW}  ⚠ screen not found (install: sudo apt install screen)${NC}"
    echo "    screen is recommended but not required"
else
    echo -e "${GREEN}  ✓ screen installed${NC}"
fi

if ! systemctl is-active ssh &> /dev/null; then
    echo -e "${YELLOW}  ⚠ SSH service not running${NC}"
    echo "    Start it: sudo systemctl enable ssh && sudo systemctl start ssh"
else
    echo -e "${GREEN}  ✓ SSH service running${NC}"
fi

if [ $MISSING -eq 1 ]; then
    echo ""
    echo -e "${RED}Please install missing dependencies and run setup again.${NC}"
    exit 1
fi

echo ""

# ---- Step 2: Ngrok auth ----
echo -e "${YELLOW}[2/5] Checking ngrok authentication...${NC}"

NGROK_CONFIG=$(ngrok config check 2>&1)
if echo "$NGROK_CONFIG" | grep -q "Valid"; then
    echo -e "${GREEN}  ✓ ngrok config is valid${NC}"
else
    echo -e "${YELLOW}  ⚠ ngrok may not be authenticated${NC}"
    read -p "  Enter your ngrok authtoken (from https://dashboard.ngrok.com): " NGROK_TOKEN
    if [ -n "$NGROK_TOKEN" ]; then
        ngrok config add-authtoken "$NGROK_TOKEN"
        echo -e "${GREEN}  ✓ ngrok authtoken configured${NC}"
    else
        echo -e "${RED}  ✗ Skipped - ngrok won't work without authentication${NC}"
    fi
fi

echo ""

# ---- Step 3: Telegram configuration ----
echo -e "${YELLOW}[3/5] Configuring Telegram...${NC}"

# Load existing .env if present
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    echo "  Found existing .env file"
fi

if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ "$TELEGRAM_BOT_TOKEN" != "your_bot_token_here" ]; then
    echo "  Current bot token: ${TELEGRAM_BOT_TOKEN:0:10}..."
    read -p "  Keep current token? (Y/n): " KEEP_TOKEN
    if [[ "$KEEP_TOKEN" =~ ^[Nn]$ ]]; then
        TELEGRAM_BOT_TOKEN=""
    fi
fi

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ "$TELEGRAM_BOT_TOKEN" == "your_bot_token_here" ]; then
    echo ""
    echo "  To get a Telegram bot token:"
    echo "    1. Open Telegram and message @BotFather"
    echo "    2. Send /newbot and follow instructions"
    echo "    3. Copy the token"
    echo ""
    read -p "  Enter Telegram bot token: " TELEGRAM_BOT_TOKEN

    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        echo -e "${RED}  ✗ Bot token is required${NC}"
        exit 1
    fi
fi

if [ -n "$TELEGRAM_CHAT_ID" ] && [ "$TELEGRAM_CHAT_ID" != "your_chat_id_here" ]; then
    echo "  Current chat ID: $TELEGRAM_CHAT_ID"
    read -p "  Keep current chat ID? (Y/n): " KEEP_CHAT
    if [[ "$KEEP_CHAT" =~ ^[Nn]$ ]]; then
        TELEGRAM_CHAT_ID=""
    fi
fi

if [ -z "$TELEGRAM_CHAT_ID" ] || [ "$TELEGRAM_CHAT_ID" == "your_chat_id_here" ]; then
    echo ""
    echo "  To get your chat ID:"
    echo "    1. Send any message to your bot on Telegram"
    echo "    2. Enter your chat ID below"
    echo "    (Find it at: https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates)"
    echo ""
    read -p "  Enter Telegram chat ID: " TELEGRAM_CHAT_ID

    if [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo -e "${RED}  ✗ Chat ID is required${NC}"
        exit 1
    fi
fi

# Optional settings
SSH_USER="${SSH_USER:-$(whoami)}"
read -p "  SSH username [$SSH_USER]: " INPUT_USER
SSH_USER="${INPUT_USER:-$SSH_USER}"

NGROK_PORT="${NGROK_PORT:-22}"
read -p "  SSH port [$NGROK_PORT]: " INPUT_PORT
NGROK_PORT="${INPUT_PORT:-$NGROK_PORT}"

# Write .env
cat > "$ENV_FILE" << EOF
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID

# Ngrok Configuration
NGROK_PORT=$NGROK_PORT
NGROK_PROTOCOL=tcp
SSH_USER=$SSH_USER
EOF

chmod 600 "$ENV_FILE"
echo -e "${GREEN}  ✓ Config saved to .env${NC}"

echo ""

# ---- Step 4: Test Telegram ----
echo -e "${YELLOW}[4/5] Testing Telegram notification...${NC}"

RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d text="✅ bot2ssh setup complete! Notifications are working." \
    -d parse_mode="HTML")

if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo -e "${GREEN}  ✓ Telegram test message sent! Check your Telegram.${NC}"
else
    echo -e "${RED}  ✗ Failed to send Telegram message${NC}"
    echo "  Response: $RESPONSE"
    echo ""
    echo "  Common issues:"
    echo "    - Bot token is incorrect"
    echo "    - Chat ID is wrong"
    echo "    - You haven't sent a message to the bot yet"
    echo ""
    read -p "  Continue anyway? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""

# ---- Step 5: Auto-start on boot ----
echo -e "${YELLOW}[5/5] Setting up auto-start on boot...${NC}"

CRON_CMD="@reboot sleep 15 && screen -dmS ngrok ${SCRIPT_DIR}/run_monitor.sh"
EXISTING_CRON=$(crontab -l 2>/dev/null | grep "run_monitor.sh" || true)

if [ -n "$EXISTING_CRON" ]; then
    echo "  Existing crontab entry found:"
    echo "    $EXISTING_CRON"
    read -p "  Replace it? (Y/n): " REPLACE
    if [[ ! "$REPLACE" =~ ^[Nn]$ ]]; then
        (crontab -l 2>/dev/null | grep -v "run_monitor.sh"; echo "$CRON_CMD") | crontab -
        echo -e "${GREEN}  ✓ Crontab updated${NC}"
    fi
else
    read -p "  Enable auto-start on boot? (Y/n): " AUTOSTART
    if [[ ! "$AUTOSTART" =~ ^[Nn]$ ]]; then
        (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
        echo -e "${GREEN}  ✓ Crontab entry added${NC}"
    else
        echo "  Skipped. Run manually: screen -S ngrok ./run_monitor.sh"
    fi
fi

echo ""

# ---- Done ----
echo "========================================"
echo -e "${GREEN}  ✓ Setup complete!${NC}"
echo "========================================"
echo ""
echo "  Start the monitor now:"
echo "    screen -S ngrok ./run_monitor.sh"
echo ""
echo "  Or start in background:"
echo "    screen -dmS ngrok ./run_monitor.sh"
echo ""
echo "  View monitor:   screen -r ngrok"
echo "  Detach:         Ctrl+A then D"
echo "  Stop:           screen -r ngrok then Ctrl+C"
echo ""

read -p "Start the monitor now? (Y/n): " START_NOW
if [[ ! "$START_NOW" =~ ^[Nn]$ ]]; then
    screen -S ngrok -X quit 2>/dev/null
    pkill -9 ngrok 2>/dev/null
    sleep 1
    screen -dmS ngrok "$SCRIPT_DIR/run_monitor.sh"
    echo ""
    echo -e "${GREEN}  ✓ Monitor started! Check your Telegram for connection details.${NC}"
fi

echo ""
