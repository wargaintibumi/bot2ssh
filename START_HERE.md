# 🚀 Ngrok Monitor - Quick Start Guide

## ✅ Your script is ready! Here's how to use it:

### First-Time Setup

```bash
cd /home/kali/bot2ssh
./setup.sh
```

This will configure your Telegram bot, choose protocol (TCP or HTTP), and optionally enable auto-start on boot.

### Option 1: Run in Screen (Recommended)

```bash
cd /home/kali/bot2ssh
screen -S ngrok ./run_monitor.sh
```

**To detach (leave it running)**: Press `Ctrl+A` then `D`
**To reconnect later**: `screen -r ngrok`
**To stop**: Reconnect and press `Ctrl+C`

### Option 2: Run in a Terminal

Just keep a terminal open:
```bash
cd /home/kali/bot2ssh
./run_monitor.sh
```

Press `Ctrl+C` to stop.

## 📱 What You'll Get

Every time ngrok starts or restarts, you'll receive a Telegram message with:

**TCP mode (SSH tunnel):**
- ✅ Ngrok URL (e.g., `tcp://0.tcp.ap.ngrok.io:12345`)
- ✅ Host and Port
- ✅ Ready-to-use SSH command: `ssh -p PORT kali@HOST`
- ✅ Timestamp

**HTTP mode (web app tunnel):**
- ✅ Public URL (e.g., `https://abcd1234.ngrok-free.app`)
- ✅ Local port being forwarded
- ✅ Timestamp

## 🔄 Auto-Restart Feature

The script monitors ngrok every 10 seconds. If it crashes or gets terminated:
1. ⚠️ You'll get a "Disconnected" Telegram message
2. 🔄 Script automatically restarts ngrok
3. 📱 You'll get a new message with the new connection details

## 📝 Files

- `setup.sh` - Interactive setup wizard
- `run_monitor.sh` - Main monitoring script
- `uninstall.sh` - Remove crontab, kill processes, clean up
- `test_telegram.sh` - Test Telegram notifications
- `START_HERE.md` - This guide

## 🛠️ Troubleshooting

**Ngrok not installed?**
```bash
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz
tar xvzf ngrok-v3-stable-linux-arm64.tgz
sudo mv ngrok /usr/local/bin/
ngrok authtoken YOUR_AUTH_TOKEN_FROM_NGROK_COM
```

**No Telegram messages?**
```bash
./test_telegram.sh  # Test if Telegram works
```

**Check if ngrok is running:**
```bash
curl -s http://localhost:4040/api/tunnels | grep public_url
```

**View all screen sessions:**
```bash
screen -ls
```

## 🎯 One-Command Start

```bash
cd /home/kali/bot2ssh && screen -S ngrok ./run_monitor.sh
```

Then press `Ctrl+A` then `D` to detach and let it run!

---

**That's it! Your tunnel will auto-restart and you'll always get notified!** 🎉
