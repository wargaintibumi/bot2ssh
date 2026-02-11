# Ngrok SSH Monitor with Telegram Notifications

## Project Overview

This project provides an automated monitoring system for ngrok SSH tunnels with Telegram notifications. When ngrok starts, restarts, or fails, you'll receive instant notifications with connection details.

## Features

- 🔄 **Auto-restart**: Automatically restarts ngrok when it terminates
- 📱 **Telegram notifications**: Sends SSH connection details via Telegram bot
- 🔐 **SSH tunnel monitoring**: Monitors TCP tunnel on port 22
- ⚡ **Automatic URL extraction**: Gets ngrok URL from API automatically
- 🎨 **Colored terminal output**: Easy-to-read status messages
- ✅ **Reliable**: Runs in screen session for persistence

## Quick Start

### Run the Monitor

```bash
cd /home/kali/bot2ssh
screen -S ngrok ./run_monitor.sh
```

Press `Ctrl+A` then `D` to detach and leave it running.

### Reconnect to Monitor

```bash
screen -r ngrok
```

### Stop the Monitor

```bash
screen -r ngrok  # then press Ctrl+C
```

## Configuration

### Telegram Bot Setup

1. The bot token and chat ID are already configured in the scripts
2. To change them, edit:
   - `run_monitor.sh`
   - `ngrok_monitor_final.sh`
   - `test_telegram.sh`

### Ngrok Configuration

- **Port**: 22 (SSH)
- **Protocol**: TCP
- **Auth token**: Configured in `~/.config/ngrok/ngrok.yml`

## Files

- **run_monitor.sh** - Main monitoring script (recommended)
- **test_telegram.sh** - Test Telegram notifications
- **START_HERE.md** - Detailed user guide
- **CLAUDE.md** - This file
- **ngrok_monitor_final.sh** - Alternative monitor script
- **ngrok-monitor.service** - Systemd service file (not recommended due to issues)

## Architecture

The monitor works by:

1. Starting ngrok with TCP tunnel on port 22
2. Querying ngrok's local API (http://localhost:4040/api/tunnels)
3. Extracting the public URL
4. Sending connection details via Telegram API
5. Monitoring ngrok process every 10 seconds
6. Auto-restarting and notifying on failures

## Troubleshooting

### Ngrok keeps dying

- Check if systemd service is running: `sudo systemctl status ngrok-monitor`
- If yes, stop it: `sudo systemctl stop ngrok-monitor && sudo systemctl disable ngrok-monitor`
- The screen-based approach is more reliable

### No Telegram notifications

- Test with: `./test_telegram.sh`
- Verify bot token and chat ID are correct
- Make sure you've sent at least one message to the bot first

### SSH connection fails

- Verify SSH service is running: `sudo systemctl status ssh`
- Check current ngrok URL: `curl -s http://localhost:4040/api/tunnels | grep public_url`
- Test SSH locally: `ssh localhost`
- Make sure you're using the correct username and password/key

### Screen session died

- Check screen output: `screen -S ngrok -X hardcopy /tmp/screen.txt && cat /tmp/screen.txt`
- View logs: Check /tmp/ngrok_monitor.log if using v2 script

## Git Configuration

This repository is configured for:
- **Username**: wargaintibumi
- **Email**: adialfian49@gmail.com

## Requirements

- ngrok (version 3.x)
- bash
- curl
- screen (optional but recommended)
- SSH server running on port 22
- Telegram bot token and chat ID

## License

Free to use and modify.

## Support

For issues or questions, check the logs or screen output for error messages.
