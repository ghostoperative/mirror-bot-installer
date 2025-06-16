# Mirror-Leech-Telegram-Bot Quick Start Guide

This quick start guide will help you get the Mirror-Leech-Telegram-Bot up and running on your DigitalOcean server.

## Prerequisites

Before you start, make sure you have:

1. A DigitalOcean droplet (Ubuntu 20.04 or later)
2. SSH access to your droplet
3. The following credentials:
   - Telegram Bot Token (from [@BotFather](https://t.me/BotFather))
   - Telegram API ID & Hash (from [my.telegram.org](https://my.telegram.org))
   - Your Telegram User ID (from [@userinfobot](https://t.me/userinfobot))
   - MongoDB URI (from [mongodb.com](https://mongodb.com))

## Quick Installation

1. SSH into your DigitalOcean server:
   ```bash
   ssh root@your_server_ip
   ```

2. Download the installation script:
   ```bash
   curl -O https://raw.githubusercontent.com/yourusername/mirror-bot-installer/main/install_mirror_bot.sh
   ```

3. Make the script executable:
   ```bash
   chmod +x install_mirror_bot.sh
   ```

4. Run the installation script and follow the prompts:
   ```bash
   sudo ./install_mirror_bot.sh
   ```

5. The script will ask for your credentials and set up everything automatically.

6. When the installation is complete, the bot will be running in the background.

## Managing Your Bot

- **View logs**: `cd /opt/mirror-leech-bot && docker compose logs --follow`
- **Stop bot**: `cd /opt/mirror-leech-bot && docker compose stop`
- **Start bot**: `cd /opt/mirror-leech-bot && docker compose start`
- **Restart bot**: `cd /opt/mirror-leech-bot && docker compose restart`

## Basic Commands

Once your bot is running, you can use these commands in Telegram:

- `/mirror <link>`: Download a file and upload it to Google Drive
- `/leech <link>`: Download a file and upload it to Telegram
- `/qbmirror <link>`: Mirror a torrent using qBittorrent
- `/qbleech <link>`: Leech a torrent using qBittorrent
- `/status`: Check the status of all downloads
- `/bsetting`: Access bot settings menu

## Get Help

For more detailed instructions, see the full README.md file or join the official Telegram support group at [https://t.me/mltb_official_support](https://t.me/mltb_official_support).
