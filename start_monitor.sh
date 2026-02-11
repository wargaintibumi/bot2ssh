#!/bin/bash

# Simple launcher for ngrok monitor

echo "Starting Ngrok Monitor..."
echo "Log file: /tmp/ngrok_monitor.log"
echo ""
echo "To stop the monitor, run: pkill -f ngrok_monitor_v2"
echo "To view the log, run: tail -f /tmp/ngrok_monitor.log"
echo ""

cd /home/kali/bot2ssh

# Run in screen if available, otherwise just run directly
if command -v screen &> /dev/null; then
    screen -dmS ngrok_monitor ./ngrok_monitor_v2.sh
    echo "✓ Monitor started in screen session 'ngrok_monitor'"
    echo "To view: screen -r ngrok_monitor"
    echo "To detach: Press Ctrl+A then D"
else
    nohup ./ngrok_monitor_v2.sh >/dev/null 2>&1 &
    echo "✓ Monitor started in background (PID: $!)"
fi

echo ""
echo "Wait a few seconds and check your Telegram for the SSH connection details!"
