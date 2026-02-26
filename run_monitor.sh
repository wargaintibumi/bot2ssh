#!/bin/bash

# Simple and reliable ngrok monitor
# Run this in a terminal and leave it running, or use: screen -S ngrok ./run_monitor.sh

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found. Run ./setup.sh first."
    exit 1
fi

source "$ENV_FILE"

NGROK_PORT="${NGROK_PORT:-22}"
NGROK_PROTOCOL="${NGROK_PROTOCOL:-tcp}"
SSH_USER="${SSH_USER:-kali}"

send_telegram() {
    local RESPONSE
    RESPONSE=$(curl -s --max-time 10 -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="$1" \
        -d parse_mode="HTML")
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        return 0
    else
        echo "[$(date '+%H:%M:%S')] ✗ Telegram failed: $RESPONSE"
        return 1
    fi
}

# Wait for internet connectivity before doing anything
wait_for_network() {
    echo "[$(date '+%H:%M:%S')] Waiting for network..."
    local attempts=0
    while ! curl -s --max-time 3 https://api.telegram.org > /dev/null 2>&1; do
        attempts=$((attempts + 1))
        if [ $((attempts % 10)) -eq 0 ]; then
            echo "[$(date '+%H:%M:%S')] Still waiting for network... (attempt $attempts)"
        fi
        sleep 3
    done
    echo "[$(date '+%H:%M:%S')] ✓ Network is up"
}

start_ngrok() {
    echo "[$(date '+%H:%M:%S')] Starting ngrok..."

    pkill -9 ngrok 2>/dev/null
    sleep 2

    ngrok ${NGROK_PROTOCOL} ${NGROK_PORT} --log=/tmp/ngrok.log --log-level=info &
    sleep 5

    # Retry getting URL a few times
    local attempt=1
    local URL=""
    while [ $attempt -le 5 ] && [ -z "$URL" ]; do
        URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"[^"]*' | head -1 | cut -d'"' -f4)
        if [ -z "$URL" ]; then
            sleep 2
            attempt=$((attempt + 1))
        fi
    done

    if [ -n "$URL" ]; then
        echo "[$(date '+%H:%M:%S')] ✓ Ngrok URL: $URL"

        if [ "$NGROK_PROTOCOL" = "tcp" ]; then
            HOST=$(echo "$URL" | sed 's/tcp:\/\///' | cut -d':' -f1)
            PORT=$(echo "$URL" | sed 's/tcp:\/\///' | cut -d':' -f2)
            echo "[$(date '+%H:%M:%S')] ✓ Host: $HOST Port: $PORT"
            MSG="<b>🚀 Ngrok SSH Tunnel Active</b>%0A%0A<b>URL:</b> <code>${URL}</code>%0A<b>Host:</b> <code>${HOST}</code>%0A<b>Port:</b> <code>${PORT}</code>%0A%0A<b>SSH:</b> <code>ssh -p ${PORT} ${SSH_USER}@${HOST}</code>%0A%0A<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S')"
        else
            MSG="<b>🚀 Ngrok Web Tunnel Active</b>%0A%0A<b>URL:</b> <code>${URL}</code>%0A<b>Local port:</b> <code>${NGROK_PORT}</code>%0A%0A<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S')"
        fi

        if send_telegram "$MSG"; then
            echo "[$(date '+%H:%M:%S')] ✓ Telegram sent"
        else
            echo "[$(date '+%H:%M:%S')] Retrying Telegram in 5s..."
            sleep 5
            if send_telegram "$MSG"; then
                echo "[$(date '+%H:%M:%S')] ✓ Telegram sent (retry)"
            else
                echo "[$(date '+%H:%M:%S')] ✗ Telegram notification failed"
            fi
        fi
    else
        echo "[$(date '+%H:%M:%S')] ✗ Failed to get URL"
        echo "[$(date '+%H:%M:%S')] Check /tmp/ngrok.log for details"
        send_telegram "⚠️ Ngrok failed to start"
    fi
}

echo "========================================"
echo "Ngrok Monitor - $(date)"
echo "========================================"
echo ""

# Wait for network before first start
wait_for_network

start_ngrok

echo ""
echo "Monitoring... (Press Ctrl+C to stop)"
echo ""

while true; do
    sleep 10

    if ! pgrep -x ngrok > /dev/null 2>&1; then
        echo "[$(date '+%H:%M:%S')] ✗ Ngrok died! Restarting..."
        send_telegram "⚠️ <b>Ngrok Disconnected</b>%0ARestarting..."
        sleep 5
        wait_for_network
        start_ngrok
        echo ""
    fi
done
