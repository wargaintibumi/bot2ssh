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
LOG_FILE="/tmp/ngrok_monitor.log"

# Redirect all output to log file
exec > "$LOG_FILE" 2>&1

echo "=================================="
echo "Ngrok Monitor Started"
echo "Time: $(date)"
echo "=================================="
echo ""

# Function to send Telegram message
send_telegram() {
    local message="$1"
    local response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" \
        -d parse_mode="HTML")

    if echo "$response" | grep -q '"ok":true'; then
        echo "[$(date '+%H:%M:%S')] ✓ Telegram notification sent"
        return 0
    else
        echo "[$(date '+%H:%M:%S')] ✗ Failed to send Telegram notification"
        return 1
    fi
}

# Function to get ngrok URL
get_ngrok_url() {
    local max_attempts=15
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        sleep 2

        local response=$(curl -s ${NGROK_API} 2>/dev/null)

        if [ -n "$response" ]; then
            local url=$(echo "$response" | grep -o '"public_url":"tcp://[^"]*' | cut -d'"' -f4)

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
    echo "[$(date '+%H:%M:%S')] Starting ngrok..."

    # Kill any existing ngrok processes
    pkill -9 ngrok 2>/dev/null
    sleep 2

    # Start ngrok in background
    setsid ngrok ${NGROK_PROTOCOL} ${NGROK_PORT} >/dev/null 2>&1 < /dev/null &
    sleep 3

    # Verify ngrok process started
    if pgrep -x ngrok > /dev/null; then
        local ngrok_pid=$(pgrep -x ngrok)
        echo "[$(date '+%H:%M:%S')] ✓ Ngrok started (PID: ${ngrok_pid})"
    else
        echo "[$(date '+%H:%M:%S')] ✗ Failed to start ngrok"
        send_telegram "⚠️ <b>Failed to start ngrok</b>"
        return 1
    fi

    # Wait for ngrok to initialize and get URL
    echo "[$(date '+%H:%M:%S')] Waiting for ngrok URL..."
    local url=$(get_ngrok_url)

    if [ -n "$url" ]; then
        echo "[$(date '+%H:%M:%S')] ✓ Ngrok URL: ${url}"

        # Extract host and port
        local host=$(echo "$url" | sed 's/tcp:\/\///' | cut -d':' -f1)
        local port=$(echo "$url" | sed 's/tcp:\/\///' | cut -d':' -f2)

        # Send Telegram notification
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local message="<b>🚀 Ngrok SSH Tunnel Active</b>%0A%0A"
        message+="<b>URL:</b> <code>${url}</code>%0A"
        message+="<b>Host:</b> <code>${host}</code>%0A"
        message+="<b>Port:</b> <code>${port}</code>%0A%0A"
        message+="<b>SSH Command:</b>%0A<code>ssh -p ${port} kali@${host}</code>%0A%0A"
        message+="<b>Time:</b> ${timestamp}"

        send_telegram "$message"
    else
        echo "[$(date '+%H:%M:%S')] ✗ Failed to get ngrok URL"
        send_telegram "⚠️ Ngrok started but failed to retrieve URL"
    fi
}

# Function to check if ngrok is running
is_ngrok_running() {
    pgrep -x ngrok > /dev/null
    return $?
}

# Trap Ctrl+C
trap 'echo ""; echo "[$(date '\''+%H:%M:%S'\'')] Stopping monitor..."; pkill -9 ngrok 2>/dev/null; exit 0' INT TERM

# Check if Telegram credentials are set
if [ "$TELEGRAM_BOT_TOKEN" == "YOUR_BOT_TOKEN_HERE" ] || [ "$TELEGRAM_CHAT_ID" == "YOUR_CHAT_ID_HERE" ]; then
    echo "Error: Please set your Telegram bot token and chat ID in the script"
    exit 1
fi

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "Error: ngrok is not installed"
    exit 1
fi

# Initial start
start_ngrok

echo ""
echo "[$(date '+%H:%M:%S')] Monitoring ngrok process..."
echo "[$(date '+%H:%M:%S')] Log file: $LOG_FILE"
echo ""

# Monitor loop
while true; do
    sleep 5

    if ! is_ngrok_running; then
        echo "[$(date '+%H:%M:%S')] ✗ Ngrok process terminated!"
        send_telegram "⚠️ <b>Ngrok Disconnected</b>%0A%0ARestarting tunnel..."
        sleep 2
        start_ngrok
        echo ""
    fi
done
