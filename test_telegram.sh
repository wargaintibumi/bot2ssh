#!/bin/bash

TELEGRAM_BOT_TOKEN="8554464196:AAGlulCcLyW1rdcPNzpT7GtIVXLn_qSu3P4"
TELEGRAM_CHAT_ID="678764716"

# Start ngrok
echo "Starting ngrok..."
setsid ngrok tcp 22 > /tmp/ngrok.log 2>&1 < /dev/null &
sleep 5

# Get URL
echo "Getting ngrok URL..."
URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"tcp://[^"]*' | cut -d'"' -f4)

if [ -n "$URL" ]; then
    echo "Ngrok URL: $URL"

    # Extract host and port
    HOST=$(echo "$URL" | sed 's/tcp:\/\///' | cut -d':' -f1)
    PORT=$(echo "$URL" | sed 's/tcp:\/\///' | cut -d':' -f2)

    echo "Host: $HOST"
    echo "Port: $PORT"

    # Send Telegram
    echo "Sending Telegram notification..."
    MESSAGE="<b>🚀 Ngrok SSH Tunnel Active</b>%0A%0A<b>URL:</b> <code>${URL}</code>%0A<b>Host:</b> <code>${HOST}</code>%0A<b>Port:</b> <code>${PORT}</code>%0A%0A<b>SSH Command:</b>%0A<code>ssh -p ${PORT} kali@${HOST}</code>"

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${MESSAGE}" \
        -d parse_mode="HTML"

    echo ""
    echo "Done! Check your Telegram"
else
    echo "Failed to get ngrok URL"
    exit 1
fi
