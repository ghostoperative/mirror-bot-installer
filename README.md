# Mirror-Leech-Telegram-Bot Installation Guide for DigitalOcean

This guide provides instructions to install and configure [anasty17/mirror-leech-telegram-bot](https://github.com/anasty17/mirror-leech-telegram-bot) on a DigitalOcean server.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Required Credentials](#required-credentials)
- [Configuration Options](#configuration-options)
- [Managing the Bot](#managing-the-bot)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting the installation, make sure you have:

1. A DigitalOcean droplet (recommended minimum: 2GB RAM, 2 vCPUs, 50GB storage)
2. Ubuntu 20.04 or later installed on the droplet
3. Root or sudo access to the server
4. Domain name (optional, but recommended for better accessibility)

## Required Credentials

You'll need to obtain the following credentials before installation:

1. **Telegram Bot Token**: Create a new bot using [@BotFather](https://t.me/BotFather) on Telegram
2. **Telegram API ID & Hash**: Obtain from [my.telegram.org](https://my.telegram.org)
3. **MongoDB URI**: Create a free MongoDB database at [mongodb.com](https://mongodb.com)
4. **User Telegram ID**: Your Telegram user ID (can be obtained using [@userinfobot](https://t.me/userinfobot))
5. **Google Drive credentials** (optional): For Google Drive integration
   - OAuth client credentials from Google Developer Console
   - Google Drive folder ID or TeamDrive ID

## Installation

### Option 1: Automated Installation

1. SSH into your DigitalOcean server:
   ```bash
   ssh root@your_server_ip
   ```

2. Download the installation script:
   ```bash
   wget -O install_mirror_bot.sh https://raw.githubusercontent.com/yourusername/mirror-bot-installer/main/install_mirror_bot.sh
   ```

3. Make the script executable:
   ```bash
   chmod +x install_mirror_bot.sh
   ```

4. Run the installation script:
   ```bash
   sudo ./install_mirror_bot.sh
   ```

5. Follow the on-screen instructions to configure the bot.

### Option 2: Manual Installation

If you prefer to install manually:

1. SSH into your DigitalOcean server
2. Update system packages:
   ```bash
   apt update && apt upgrade -y
   ```

3. Install required packages:
   ```bash
   apt install -y python3 python3-pip git curl wget unzip docker.io docker-compose-plugin
   ```

4. Enable Docker service:
   ```bash
   systemctl enable docker
   systemctl start docker
   ```

5. Clone the repository:
   ```bash
   mkdir -p /opt/mirror-leech-bot
   cd /opt/mirror-leech-bot
   git clone https://github.com/anasty17/mirror-leech-telegram-bot .
   ```

6. Install Python dependencies:
   ```bash
   pip3 install -r requirements-cli.txt
   ```

7. Create config file:
   ```bash
   cp config_sample.py config.py
   ```

8. Edit the config file:
   ```bash
   nano config.py
   ```

9. Build and start the Docker container:
   ```bash
   docker compose up --build -d
   ```

## Configuration Options

The `config.py` file contains various settings for the bot. Here are the most important ones:

### Required Settings

- `BOT_TOKEN`: Your Telegram Bot Token from @BotFather
- `OWNER_ID`: Your Telegram User ID (numeric)
- `TELEGRAM_API`: Your Telegram API ID
- `TELEGRAM_HASH`: Your Telegram API Hash
- `DATABASE_URL`: MongoDB connection URI

### Optional Settings

- `GDRIVE_ID`: Google Drive Folder ID or TeamDrive ID
- `IS_TEAM_DRIVE`: Set to True if using a TeamDrive
- `INDEX_URL`: Your Google Drive Index URL
- `RCLONE_PATH`: Default rclone path for uploads
- `BASE_URL`: Your server's IP or domain (e.g., http://123.123.123.123)
- `BASE_URL_PORT`: Port for the BASE_URL (default: 80)

## Google Drive Setup

To use Google Drive functionality:

1. Visit [Google Cloud Console](https://console.developers.google.com/apis/credentials)
2. Create a new project
3. Configure OAuth consent screen
4. Create Credentials -> OAuth Client ID -> Desktop app
5. Download the credentials.json file
6. Place it in the bot directory
7. Run the token generator:
   ```bash
   cd /opt/mirror-leech-bot
   python3 generate_drive_token.py
   ```

### Service Accounts (Optional)

For high-volume transfers, you can use service accounts:

1. Generate service accounts:
   ```bash
   cd /opt/mirror-leech-bot
   python3 gen_sa_accounts.py --quick-setup 1 --new-only
   ```

2. Add service accounts to your TeamDrive

## Rclone Setup

To use rclone for uploading:

1. Install rclone:
   ```bash
   curl https://rclone.org/install.sh | bash
   ```

2. Configure rclone:
   ```bash
   rclone config
   ```

3. Create remotes for your cloud storage platforms
4. Update the `RCLONE_PATH` in config.py

## Managing the Bot

### View Logs
```bash
cd /opt/mirror-leech-bot
docker compose logs --follow
```

### Stop the Bot
```bash
cd /opt/mirror-leech-bot
docker compose stop
```

### Start the Bot
```bash
cd /opt/mirror-leech-bot
docker compose start
```

### Restart the Bot
```bash
cd /opt/mirror-leech-bot
docker compose restart
```

### Update the Bot
```bash
cd /opt/mirror-leech-bot
git pull
docker compose up --build -d
```

## Common Tasks

### Adding Bot Commands to BotFather

Send this list to @BotFather using the /setcommands command:

```
mirror - or /m Mirror
qbmirror - or /qm Mirror torrent using qBittorrent
jdmirror - or /jm Mirror using jdownloader
nzbmirror - or /nm Mirror using sabnzbd
ytdl - or /y Mirror yt-dlp supported links
leech - or /l Upload to telegram
qbleech - or /ql Leech torrent using qBittorrent
jdleech - or /jl Leech using jdownloader
nzbleech - or /nl Leech using sabnzbd
ytdlleech - or /yl Leech yt-dlp supported links
clone - Copy file/folder to Drive
count - Count file/folder from GDrive
usetting - or /us User settings
bsetting - or /bs Bot settings
status - Get Mirror Status
sel - Select files from torrent
rss - Rss menu
list - Search files in Drive
search - Search for torrents with API
cancel - or /c Cancel a task
cancelall - Cancel all tasks
forcestart - or /fs to start task from queue
del - Delete file/folder from GDrive
log - Get the Bot Log
auth - Authorize user or chat
unauth - Unauthorize uer or chat
shell - Run commands in Shell
restart - Restart the Bot
```

### Securing Your Server

1. Set up a firewall:
   ```bash
   ufw allow ssh
   ufw allow http
   ufw allow https
   ufw allow 8080  # For rclone serve
   ufw enable
   ```

2. Create a non-root user:
   ```bash
   adduser newuser
   usermod -aG sudo newuser
   ```

3. Consider setting up SSH key authentication instead of password.

## Troubleshooting

### Bot Not Starting

Check the logs:
```bash
cd /opt/mirror-leech-bot
docker compose logs --follow
```

Common issues:
- Incorrect Telegram API credentials
- Bot token is invalid
- MongoDB URI is incorrect
- Missing required settings in config.py

### Download/Upload Issues

- Check if qBittorrent is working:
  ```bash
  docker compose exec app curl -I http://localhost:8090
  ```

- Check if your server's firewall allows required ports
- Check if your IP is blocked by certain trackers

### Google Drive Issues

- Verify token.pickle is present
- Check service account permissions if using them
- Ensure you have enough Google Drive storage quota

## Additional Resources

- [Official Repository](https://github.com/anasty17/mirror-leech-telegram-bot)
- [Official Telegram Channel](https://t.me/mltb_official_channel)
- [Official Telegram Group](https://t.me/mltb_official_support)

## Support

For questions and support, please join the official Telegram group at [https://t.me/mltb_official_support](https://t.me/mltb_official_support).
