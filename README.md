# Ngrok SSH Monitor with Telegram Notifications

This script automatically monitors ngrok, restarts it when terminated, and sends the new SSH connection details to your Telegram.

## Features

- 🔄 Auto-restart ngrok when it terminates
- 📱 Telegram notifications with connection details
- 🔐 SSH tunnel monitoring (TCP port 22)
- ⚡ Automatic URL extraction
- 🎨 Colored terminal output

## Setup Instructions

### 1. Install ngrok

If not already installed:
```bash
# Download ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz
tar xvzf ngrok-v3-stable-linux-arm64.tgz
sudo mv ngrok /usr/local/bin/

# Authenticate (get your token from https://dashboard.ngrok.com)
ngrok authtoken YOUR_NGROK_AUTH_TOKEN
```

### 2. Create Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` and follow the instructions
3. Copy the **Bot Token** you receive
4. Start a chat with your new bot
5. Get your **Chat ID**:
   - Send a message to your bot
   - Visit: `https://api.telegram.org/botYOUR_BOT_TOKEN/getUpdates`
   - Look for `"chat":{"id":` - that's your chat ID

### 3. Configure the Script

Edit the script and replace the placeholders:
```bash
nano ngrok_monitor.sh
```

Replace:
- `YOUR_BOT_TOKEN_HERE` with your Telegram bot token
- `YOUR_CHAT_ID_HERE` with your Telegram chat ID

### 4. Run the Script

```bash
./ngrok_monitor.sh
```

The script will:
- Start ngrok
- Send you the SSH connection details via Telegram
- Monitor the process
- Auto-restart and notify you if ngrok dies

## Running as a Service (Optional)

To run it automatically on boot, create a systemd service:

```bash
sudo nano /etc/systemd/system/ngrok-monitor.service
```

Add:
```ini
[Unit]
Description=Ngrok SSH Monitor with Telegram Notifications
After=network.target

[Service]
Type=simple
User=kali
WorkingDirectory=/home/kali/bot2ssh
ExecStart=/home/kali/bot2ssh/ngrok_monitor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable ngrok-monitor
sudo systemctl start ngrok-monitor
sudo systemctl status ngrok-monitor
```

## Usage

The Telegram message will contain:
- Full ngrok URL (e.g., `tcp://0.tcp.ngrok.io:12345`)
- Host and port separated
- Ready-to-use SSH command
- Timestamp

Example notification:
```
🚀 Ngrok SSH Tunnel Active

URL: tcp://0.tcp.ngrok.io:12345
Host: 0.tcp.ngrok.io
Port: 12345

SSH Command:
ssh -p 12345 user@0.tcp.ngrok.io

Time: 2026-02-11 10:30:00
```

## Stopping the Monitor

Press `Ctrl+C` to stop the monitoring script. This will also terminate ngrok.

## Troubleshooting

**Script won't start:**
- Make sure you've set the Telegram credentials
- Check that ngrok is installed: `which ngrok`

**No Telegram notifications:**
- Verify your bot token and chat ID
- Make sure you've sent at least one message to the bot
- Check internet connection

**Ngrok fails to start:**
- Make sure you've authenticated ngrok: `ngrok authtoken YOUR_TOKEN`
- Check if port 22 is available: `sudo netstat -tlnp | grep :22`

## Customization

To change the port or protocol, edit these variables in the script:
```bash
NGROK_PORT=22          # Change to your desired port
NGROK_PROTOCOL="tcp"   # or "http", "https"
```
