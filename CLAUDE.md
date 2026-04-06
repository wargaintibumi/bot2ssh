# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Ngrok tunnel monitor with Telegram notifications. Runs ngrok (TCP for SSH or HTTP for web), auto-restarts on failure, and sends connection details to Telegram.

## Key Commands

```bash
# Run the ngrok monitor (recommended: inside screen)
screen -S ngrok ./run_monitor.sh

# Restart monitor (kills existing, starts fresh in screen)
./restart.sh

# Test Telegram notifications
./test_telegram.sh

# Interactive setup (creates .env)
./setup.sh

# Uninstall (removes crontab, kills processes)
./uninstall.sh
```

## Architecture

- **`run_monitor.sh`** — The main script. Monitors ngrok tunnel and acts as a Telegram bot. Polls for bot commands every ~3s and checks ngrok health every ~9s. Bot commands: WiFi management (`/wifi`, `/scan`, `/disconnect`, `/forget`, `/saved`), system info (`/status`, `/ip`, `/ping`), and `/reboot`. Only responds to the authorized `TELEGRAM_CHAT_ID`.
- **`.env`** — All runtime config: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `NGROK_PORT` (default 22), `NGROK_PROTOCOL` (tcp|http), `SSH_USER` (default kali). Created by `setup.sh`. **Never committed** (in `.gitignore`).
- **`restart.sh`** — Kills existing screen/ngrok, relaunches `run_monitor.sh` in a detached screen session.
- **`setup.sh`** — Interactive wizard that writes `.env` and optionally configures boot crontab.
- **`ngrok_monitor_final.sh`** — Older alternative monitor script (not primary).

## Conventions

- All scripts use `#!/bin/bash` and source `.env` from `SCRIPT_DIR`.
- Telegram messages use HTML parse mode (`parse_mode=HTML`).
- Ngrok URL is extracted via: `curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | head -1 | cut -d'"' -f4`
- Log output goes to `/tmp/ngrok.log`; scripts use timestamped `[HH:MM:SS]` console output.

## Git

- **User**: wargaintibumi / adialfian49@gmail.com
- `.env` is gitignored; `.env.example` shows the template.
