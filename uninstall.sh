#!/bin/bash

# ============================================
# bot2ssh Uninstall Script
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  bot2ssh - Uninstall"
echo "========================================"
echo ""

# ---- Step 1: Remove crontab entry ----
EXISTING_CRON=$(crontab -l 2>/dev/null | grep "run_monitor.sh" || true)

if [ -n "$EXISTING_CRON" ]; then
    echo -e "${YELLOW}Found crontab entry:${NC}"
    echo "  $EXISTING_CRON"
    read -p "Remove it? (Y/n): " REMOVE_CRON
    if [[ ! "$REMOVE_CRON" =~ ^[Nn]$ ]]; then
        crontab -l 2>/dev/null | grep -v "run_monitor.sh" | crontab -
        echo -e "${GREEN}  ✓ Crontab entry removed${NC}"
    else
        echo "  Skipped"
    fi
else
    echo -e "${GREEN}  ✓ No crontab entry found${NC}"
fi

echo ""

# ---- Step 2: Kill running processes ----
if pgrep -x ngrok > /dev/null 2>&1; then
    read -p "Kill running ngrok process? (Y/n): " KILL_NGROK
    if [[ ! "$KILL_NGROK" =~ ^[Nn]$ ]]; then
        pkill -9 ngrok 2>/dev/null
        echo -e "${GREEN}  ✓ ngrok stopped${NC}"
    else
        echo "  Skipped"
    fi
else
    echo -e "${GREEN}  ✓ ngrok is not running${NC}"
fi

if screen -ls 2>/dev/null | grep -q "ngrok"; then
    read -p "Kill ngrok screen session? (Y/n): " KILL_SCREEN
    if [[ ! "$KILL_SCREEN" =~ ^[Nn]$ ]]; then
        screen -S ngrok -X quit 2>/dev/null
        echo -e "${GREEN}  ✓ Screen session killed${NC}"
    else
        echo "  Skipped"
    fi
else
    echo -e "${GREEN}  ✓ No ngrok screen session found${NC}"
fi

echo ""

# ---- Step 3: Optionally delete .env ----
if [ -f "$SCRIPT_DIR/.env" ]; then
    read -p "Delete .env file (contains your Telegram credentials)? (y/N): " DEL_ENV
    if [[ "$DEL_ENV" =~ ^[Yy]$ ]]; then
        rm "$SCRIPT_DIR/.env"
        echo -e "${GREEN}  ✓ .env deleted${NC}"
    else
        echo "  Kept .env"
    fi
else
    echo -e "${GREEN}  ✓ No .env file found${NC}"
fi

echo ""

# ---- Step 4: Optionally delete the project directory ----
echo -e "${RED}Delete the entire bot2ssh directory ($SCRIPT_DIR)?${NC}"
read -p "This cannot be undone! (y/N): " DEL_DIR
if [[ "$DEL_DIR" =~ ^[Yy]$ ]]; then
    read -p "Are you sure? Type 'yes' to confirm: " CONFIRM
    if [ "$CONFIRM" = "yes" ]; then
        rm -rf "$SCRIPT_DIR"
        echo -e "${GREEN}  ✓ bot2ssh directory deleted${NC}"
    else
        echo "  Cancelled"
    fi
else
    echo "  Kept bot2ssh directory"
fi

echo ""
echo "========================================"
echo -e "${GREEN}  ✓ Uninstall complete${NC}"
echo "========================================"
echo ""
