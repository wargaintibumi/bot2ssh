#!/bin/bash

# Simple and reliable ngrok monitor
# Run this in a terminal and leave it running, or use: screen -S ngrok ./run_monitor.sh

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

TELEGRAM_BOT_TOKEN="8554464196:AAGlulCcLyW1rdcPNzpT7GtIVXLn_qSu3P4"
TELEGRAM_CHAT_ID="678764716"

send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="$1" \
        -d parse_mode="HTML" > /dev/null
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

    ngrok tcp 22 --log=/tmp/ngrok.log --log-level=info &
    sleep 5

    # Retry getting URL a few times
    local attempt=1
    local URL=""
    while [ $attempt -le 5 ] && [ -z "$URL" ]; do
        URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"tcp://[^"]*' | cut -d'"' -f4)
        if [ -z "$URL" ]; then
            sleep 2
            attempt=$((attempt + 1))
        fi
    done

    if [ -n "$URL" ]; then
        HOST=$(echo "$URL" | sed 's/tcp:\/\///' | cut -d':' -f1)
        PORT=$(echo "$URL" | sed 's/tcp:\/\///' | cut -d':' -f2)

        echo "[$(date '+%H:%M:%S')] ✓ Ngrok URL: $URL"
        echo "[$(date '+%H:%M:%S')] ✓ Host: $HOST Port: $PORT"

        MSG="<b>🚀 Ngrok SSH Tunnel Active</b>%0A%0A<b>URL:</b> <code>${URL}</code>%0A<b>Host:</b> <code>${HOST}</code>%0A<b>Port:</b> <code>${PORT}</code>%0A%0A<b>SSH:</b> <code>ssh -p ${PORT} kali@${HOST}</code>%0A%0A<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S')"

        send_telegram "$MSG"
        echo "[$(date '+%H:%M:%S')] ✓ Telegram sent"
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
