#!/bin/bash

# Restart the ngrok monitor

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Restarting ngrok monitor...${NC}"

# Kill existing processes
screen -S ngrok -X quit 2>/dev/null
pkill -9 ngrok 2>/dev/null
sleep 2

# Start fresh
screen -dmS ngrok "$SCRIPT_DIR/run_monitor.sh"

if screen -ls 2>/dev/null | grep -q "ngrok"; then
    echo -e "${GREEN}✓ Monitor restarted! Check Telegram for new connection details.${NC}"
    echo "  View:   screen -r ngrok"
    echo "  Detach: Ctrl+A then D"
else
    echo "✗ Failed to start. Run manually: screen -S ngrok ./run_monitor.sh"
fi
