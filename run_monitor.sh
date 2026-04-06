#!/bin/bash

# Simple and reliable ngrok monitor
# Run this in a terminal and leave it running, or use: screen -S ngrok ./run_monitor.sh

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

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
BOT_OFFSET=0
API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"

send_telegram() {
    local RESPONSE
    RESPONSE=$(curl -s --max-time 10 -X POST "${API_URL}/sendMessage" \
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

send_telegram_keyboard() {
    local text="$1"
    local keyboard="$2"
    curl -s --max-time 10 -X POST "${API_URL}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"${TELEGRAM_CHAT_ID}\",
            \"text\": \"${text}\",
            \"parse_mode\": \"HTML\",
            \"reply_markup\": ${keyboard}
        }" > /dev/null 2>&1
}

register_bot_commands() {
    echo "[$(date '+%H:%M:%S')] Registering bot commands..."
    curl -s --max-time 10 -X POST "${API_URL}/setMyCommands" \
        -H "Content-Type: application/json" \
        -d '{
            "commands": [
                {"command": "menu", "description": "Show WiFi menu"},
                {"command": "scan", "description": "Scan WiFi networks"},
                {"command": "wifi", "description": "Connect: /wifi SSID|PASSWORD"},
                {"command": "disconnect", "description": "Disconnect WiFi"},
                {"command": "saved", "description": "List saved networks"},
                {"command": "forget", "description": "Forget: /forget SSID"},
                {"command": "status", "description": "WiFi connection info"},
                {"command": "ip", "description": "Show IP addresses"},
                {"command": "ping", "description": "Ping: /ping HOST"},
                {"command": "reboot", "description": "Reboot machine"},
                {"command": "help", "description": "Show all commands"}
            ]
        }' > /dev/null 2>&1
    echo "[$(date '+%H:%M:%S')] ✓ Bot commands registered"
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

# --- Telegram Bot Command Handlers ---

bot_menu() {
    local keyboard='{
        "inline_keyboard": [
            [{"text": "📡 Scan WiFi", "callback_data": "/scan"}, {"text": "📶 Status", "callback_data": "/status"}],
            [{"text": "💾 Saved Networks", "callback_data": "/saved"}, {"text": "🔌 Disconnect", "callback_data": "/disconnect"}],
            [{"text": "🌐 IP Address", "callback_data": "/ip"}, {"text": "🔄 Reboot", "callback_data": "/reboot"}],
            [{"text": "❓ Help", "callback_data": "/help"}]
        ]
    }'
    send_telegram_keyboard "<b>📡 WiFi Bot Menu</b>%0AChoose an option or type a command:" "$keyboard"
}

bot_help() {
    send_telegram "<b>📡 Bot Commands</b>

<b>WiFi:</b>
/scan — Scan available networks
/wifi SSID|PASSWORD — Connect to network
/wifi SSID — Connect to open/saved network
/disconnect — Disconnect WiFi
/forget SSID — Forget saved network
/saved — List saved networks

<b>Examples:</b>
<code>/wifi MyNetwork|secret123</code>
<code>/wifi My WiFi Name|my password</code>
<code>/wifi OpenCafe</code>
<code>/forget My WiFi Name</code>

<b>System:</b>
/status — Connection info
/ip — Show IP addresses
/ping HOST — Ping a host
/reboot — Reboot machine
/menu — Show button menu
/help — This message"
}

bot_scan() {
    send_telegram "🔍 Scanning WiFi networks..."
    nmcli device wifi rescan 2>/dev/null
    sleep 3
    local networks
    networks=$(nmcli -t -f SIGNAL,SECURITY,SSID device wifi list 2>/dev/null | sort -t: -k1 -rn | head -15)
    if [ -z "$networks" ]; then
        send_telegram "❌ No WiFi networks found."
        return
    fi
    local msg="<b>📡 Available WiFi Networks</b>%0A"
    while IFS=':' read -r signal security ssid; do
        [ -z "$ssid" ] && continue
        local lock=""
        [ -n "$security" ] && [ "$security" != "--" ] && lock="🔒"
        local bars="▁"
        [ "$signal" -ge 25 ] 2>/dev/null && bars="▂"
        [ "$signal" -ge 50 ] 2>/dev/null && bars="▄"
        [ "$signal" -ge 75 ] 2>/dev/null && bars="█"
        msg="${msg}%0A${bars} ${lock} <code>${ssid}</code> (${signal}%)"
    done <<< "$networks"
    send_telegram "$msg"
}

bot_wifi_connect() {
    local args="$1"
    if [ -z "$args" ]; then
        send_telegram "❌ Usage:
/wifi SSID|PASSWORD
/wifi SSID (open/saved network)

Examples:
<code>/wifi MyNetwork|secret123</code>
<code>/wifi My WiFi Name|my password</code>
<code>/wifi OpenNetwork</code>"
        return
    fi

    local ssid password
    if echo "$args" | grep -q '|'; then
        ssid=$(echo "$args" | sed 's/|.*//')
        password=$(echo "$args" | sed 's/[^|]*|//')
    else
        ssid="$args"
        password=""
    fi

    # Trim leading/trailing spaces
    ssid=$(echo "$ssid" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    password=$(echo "$password" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ -z "$ssid" ]; then
        send_telegram "❌ SSID cannot be empty."
        return
    fi

    send_telegram "📡 Connecting to <b>${ssid}</b>..."
    local result
    if [ -n "$password" ]; then
        result=$(nmcli device wifi connect "$ssid" password "$password" 2>&1)
    else
        result=$(nmcli device wifi connect "$ssid" 2>&1)
    fi
    if echo "$result" | grep -qi "successfully activated"; then
        sleep 2
        local ip
        ip=$(nmcli -g IP4.ADDRESS device show wlan0 2>/dev/null | head -1)
        send_telegram "✅ Connected to <b>${ssid}</b>%0AIP: <code>${ip}</code>%0A%0A🔄 Restarting ngrok tunnel..."
        # Restart ngrok since network changed
        start_ngrok
    else
        local err
        err=$(echo "$result" | tail -1)
        send_telegram "❌ Failed: <code>${err}</code>"
    fi
}

bot_disconnect() {
    nmcli device disconnect wlan0 2>/dev/null
    send_telegram "📡 WiFi disconnected."
}

bot_forget() {
    local ssid="$1"
    if [ -z "$ssid" ]; then
        send_telegram "❌ Usage: /forget SSID"
        return
    fi
    if nmcli connection delete "$ssid" 2>&1 | grep -qi "successfully deleted"; then
        send_telegram "✅ Forgot <b>${ssid}</b>"
    else
        send_telegram "❌ Could not forget <b>${ssid}</b>"
    fi
}

bot_saved() {
    local networks
    networks=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep "802-11-wireless" | cut -d: -f1)
    if [ -z "$networks" ]; then
        send_telegram "📡 No saved WiFi networks."
        return
    fi
    local msg="<b>💾 Saved Networks</b>"
    while IFS= read -r name; do
        msg="${msg}%0A• <code>${name}</code>"
    done <<< "$networks"
    send_telegram "$msg"
}

bot_status() {
    local ssid ip signal
    ssid=$(nmcli -t -f GENERAL.CONNECTION device show wlan0 2>/dev/null | cut -d: -f2)
    ip=$(nmcli -g IP4.ADDRESS device show wlan0 2>/dev/null | head -1)
    signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list 2>/dev/null | grep '^\*' | cut -d: -f2)
    if [ -z "$ssid" ] || [ "$ssid" = "--" ]; then
        send_telegram "📡 WiFi: <b>Not connected</b>"
        return
    fi
    send_telegram "<b>📡 WiFi Status</b>%0ASSID: <code>${ssid}</code>%0AIP: <code>${ip}</code>%0ASignal: ${signal}%%0AInterface: wlan0"
}

bot_ip() {
    local ips
    ips=$(ip -4 -o addr show | awk '{print $2 ": " $4}' | grep -v "^lo:")
    send_telegram "<b>🌐 IP Addresses</b>%0A<code>${ips}</code>"
}

bot_ping() {
    local host="$1"
    if [ -z "$host" ]; then
        send_telegram "❌ Usage: /ping HOST"
        return
    fi
    if ! echo "$host" | grep -qP '^[a-zA-Z0-9._-]+$'; then
        send_telegram "❌ Invalid hostname."
        return
    fi
    local result
    result=$(ping -c 3 -W 3 "$host" 2>&1 | tail -2)
    send_telegram "<b>🏓 Ping ${host}</b>%0A<code>${result}</code>"
}

bot_reboot() {
    send_telegram "🔄 Rebooting in 5 seconds..."
    sleep 5
    sudo reboot
}

process_bot_command() {
    local text="$1"
    local chat_id="$2"

    # Only respond to authorized user
    [ "$chat_id" != "$TELEGRAM_CHAT_ID" ] && return

    local cmd args
    cmd=$(echo "$text" | awk '{print tolower($1)}')
    args=$(echo "$text" | sed 's/^[^ ]* *//')
    # If no args, clear it (sed leaves the command if there's nothing after)
    [ "$args" = "$text" ] && args=""

    case "$cmd" in
        /start|/menu)    bot_menu ;;
        /help)           bot_help ;;
        /scan)           bot_scan ;;
        /wifi)           bot_wifi_connect "$args" ;;
        /disconnect)     bot_disconnect ;;
        /forget)         bot_forget "$args" ;;
        /saved)          bot_saved ;;
        /status)         bot_status ;;
        /ip)             bot_ip ;;
        /ping)           bot_ping "$args" ;;
        /reboot)         bot_reboot ;;
    esac
}

answer_callback() {
    local callback_id="$1"
    curl -s --max-time 5 -X POST "${API_URL}/answerCallbackQuery" \
        -d callback_query_id="$callback_id" > /dev/null 2>&1
}

poll_bot_commands() {
    local response
    response=$(curl -s --max-time 5 "${API_URL}/getUpdates?offset=${BOT_OFFSET}&timeout=0" 2>/dev/null)
    [ -z "$response" ] && return

    local update_ids
    update_ids=$(echo "$response" | grep -o '"update_id":[0-9]*' | grep -o '[0-9]*')

    for uid in $update_ids; do
        BOT_OFFSET=$((uid + 1))

        local text="" chat_id="" callback_id=""
        if command -v python3 > /dev/null 2>&1; then
            eval "$(echo "$response" | python3 -c "
import json, sys, shlex
data = json.load(sys.stdin)
for u in data.get('result', []):
    if u['update_id'] == ${uid}:
        msg = u.get('message', {})
        cb = u.get('callback_query', {})
        if cb:
            print('text=' + shlex.quote(cb.get('data', '')))
            print('chat_id=' + shlex.quote(str(cb.get('message', {}).get('chat', {}).get('id', ''))))
            print('callback_id=' + shlex.quote(cb.get('id', '')))
        else:
            print('text=' + shlex.quote(msg.get('text', '')))
            print('chat_id=' + shlex.quote(str(msg.get('chat', {}).get('id', ''))))
            print('callback_id=')
        break
" 2>/dev/null)"
        else
            text=$(echo "$response" | grep -o '"text":"[^"]*"' | head -1 | cut -d'"' -f4)
            chat_id=$(echo "$response" | grep -o '"chat":{"id":[0-9]*' | head -1 | grep -o '[0-9]*')
            callback_id=""
        fi

        # Acknowledge button press
        if [ -n "$callback_id" ]; then
            answer_callback "$callback_id"
        fi

        if [ -n "$text" ] && [ -n "$chat_id" ]; then
            echo "[$(date '+%H:%M:%S')] Bot cmd from $chat_id: $text"
            process_bot_command "$text" "$chat_id"
        fi
    done
}

# --- Main ---

echo "========================================"
echo "Ngrok Monitor + WiFi Bot - $(date)"
echo "========================================"
echo ""

# Wait for network before first start
wait_for_network

register_bot_commands
start_ngrok

echo ""
echo "Monitoring ngrok + polling bot commands... (Press Ctrl+C to stop)"
echo ""

MONITOR_COUNTER=0

while true; do
    # Poll for bot commands every cycle (~3s)
    poll_bot_commands

    # Check ngrok health every ~10s (every 3rd cycle)
    MONITOR_COUNTER=$((MONITOR_COUNTER + 1))
    if [ $((MONITOR_COUNTER % 3)) -eq 0 ]; then
        if ! pgrep -x ngrok > /dev/null 2>&1; then
            echo "[$(date '+%H:%M:%S')] ✗ Ngrok died! Restarting..."
            send_telegram "⚠️ <b>Ngrok Disconnected</b>%0ARestarting..."
            sleep 5
            wait_for_network
            start_ngrok
            echo ""
        fi
    fi

    sleep 3
done
