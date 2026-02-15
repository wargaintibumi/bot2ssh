#!/bin/bash

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found. Run ./setup.sh first."
    exit 1
fi

source "$ENV_FILE"

echo "Sending test message to Telegram..."

RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d text="🧪 <b>Test notification from bot2ssh</b>%0A%0ATimestamp: $(date '+%Y-%m-%d %H:%M:%S')" \
    -d parse_mode="HTML")

if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✓ Message sent! Check your Telegram."
else
    echo "✗ Failed to send message"
    echo "$RESPONSE"
fi
