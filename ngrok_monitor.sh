#!/bin/bash

# ============================================
# Ngrok Monitor with Telegram Notifications
# ============================================

# Telegram Configuration
TELEGRAM_BOT_TOKEN="8554464196:AAGlulCcLyW1rdcPNzpT7GtIVXLn_qSu3P4"
TELEGRAM_CHAT_ID="678764716"

# Ngrok Configuration
NGROK_PORT=22
NGROK_PROTOCOL="tcp"
NGROK_API="http://localhost:4040/api/tunnels"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to send Telegram message
send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" \
        -d parse_mode="HTML" > /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Telegram notification sent${NC}"
    else
        echo -e "${RED}✗ Failed to send Telegram notification${NC}"
    fi
}

# Function to get ngrok URL
get_ngrok_url() {
    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        sleep 2

        # Get tunnel info from ngrok API
        local response=$(curl -s ${NGROK_API} 2>/dev/null)

        if [ -n "$response" ]; then
            local url=$(echo "$response" | grep -o '"public_url":"[^"]*' | grep -o 'tcp://[^"]*' | head -1)

            if [ -n "$url" ]; then
                echo "$url"
                return 0
            fi
        fi

        attempt=$((attempt + 1))
    done

    return 1
}

# Function to start ngrok
start_ngrok() {
    echo -e "${YELLOW}Starting ngrok...${NC}"

    # Kill any existing ngrok processes
    pkill -9 ngrok 2>/dev/null
    sleep 1

    # Start ngrok in background using setsid to detach from terminal
    setsid ngrok ${NGROK_PROTOCOL} ${NGROK_PORT} > /tmp/ngrok.log 2>&1 < /dev/null &
    sleep 3

    # Verify ngrok process started
    if pgrep -x ngrok > /dev/null; then
        local ngrok_pid=$(pgrep -x ngrok)
        echo -e "${GREEN}✓ Ngrok started (PID: ${ngrok_pid})${NC}"
    else
        echo -e "${RED}✗ Failed to start ngrok${NC}"
        echo -e "${RED}Check /tmp/ngrok.log for details${NC}"
        return 1
    fi

    # Wait for ngrok to initialize and get URL
    echo "Waiting for ngrok URL..."
    local url=$(get_ngrok_url)

    if [ -n "$url" ]; then
        echo -e "${GREEN}✓ Ngrok URL: ${url}${NC}"

        # Extract host and port
        local host=$(echo "$url" | sed 's/tcp:\/\///' | cut -d':' -f1)
        local port=$(echo "$url" | sed 's/tcp:\/\///' | cut -d':' -f2)

        # Send Telegram notification
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local message="<b>🚀 Ngrok SSH Tunnel Active</b>%0A%0A"
        message+="<b>URL:</b> <code>${url}</code>%0A"
        message+="<b>Host:</b> <code>${host}</code>%0A"
        message+="<b>Port:</b> <code>${port}</code>%0A%0A"
        message+="<b>SSH Command:</b>%0A<code>ssh -p ${port} user@${host}</code>%0A%0A"
        message+="<b>Time:</b> ${timestamp}"

        send_telegram "$message"
    else
        echo -e "${RED}✗ Failed to get ngrok URL${NC}"
        send_telegram "⚠️ Ngrok started but failed to retrieve URL"
    fi
}

# Function to check if ngrok is running
is_ngrok_running() {
    pgrep -x ngrok > /dev/null
    return $?
}

# Main monitoring loop
main() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}Ngrok Monitor Started${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""

    # Initial start
    start_ngrok

    echo ""
    echo -e "${YELLOW}Monitoring ngrok process...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""

    # Monitor loop
    while true; do
        sleep 5

        if ! is_ngrok_running; then
            echo -e "${RED}✗ Ngrok process terminated!${NC}"
            send_telegram "⚠️ <b>Ngrok Disconnected</b>%0A%0ARestarting tunnel..."
            echo ""
            sleep 2
            start_ngrok
            echo ""
        fi
    done
}

# Trap Ctrl+C
trap 'echo -e "\n${YELLOW}Stopping monitor...${NC}"; pkill -9 ngrok 2>/dev/null; exit 0' INT TERM

# Check if Telegram credentials are set
if [ "$TELEGRAM_BOT_TOKEN" == "YOUR_BOT_TOKEN_HERE" ] || [ "$TELEGRAM_CHAT_ID" == "YOUR_CHAT_ID_HERE" ]; then
    echo -e "${RED}Error: Please set your Telegram bot token and chat ID in the script${NC}"
    exit 1
fi

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo -e "${RED}Error: ngrok is not installed${NC}"
    echo "Install it from: https://ngrok.com/download"
    exit 1
fi

# Start monitoring
main
