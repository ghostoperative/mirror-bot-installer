#!/bin/bash

# Simple script to set up mirror-leech-telegram-bot with a pre-built image
# Created to bypass pip installation issues

# Set colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}Mirror-Leech-Telegram-Bot Simple Setup${NC}"
echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}This script will set up the bot using a pre-built image.${NC}"
echo ""

# Function to ask for user input
ask_input() {
    read -p "$1: " value
    echo $value
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Update system packages
echo -e "${YELLOW}Updating system packages...${NC}"
apt update && apt upgrade -y

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt install -y python3 python3-pip git curl wget unzip

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Configure Docker DNS
echo -e "${YELLOW}Configuring Docker to use reliable DNS servers...${NC}"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOL
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
EOL
systemctl restart docker

# Create directory for the bot
echo -e "${YELLOW}Creating directory for the bot...${NC}"
mkdir -p /opt/mirror-leech-bot
cd /opt/mirror-leech-bot

# Clone the repository
echo -e "${YELLOW}Cloning repository...${NC}"
git clone https://github.com/anasty17/mirror-leech-telegram-bot .

# Get bot configuration details from user
echo -e "${GREEN}Please provide the following details for bot configuration:${NC}"
echo -e "${BLUE}This installation is configured for PRIVATE USE ONLY${NC}"

BOT_TOKEN=$(ask_input "Enter Telegram Bot Token (from @BotFather)")
OWNER_ID=$(ask_input "Enter Telegram Owner ID (your user ID, not username)")
TELEGRAM_API=$(ask_input "Enter Telegram API ID (from my.telegram.org)")
TELEGRAM_HASH=$(ask_input "Enter Telegram API Hash (from my.telegram.org)")
DATABASE_URL=$(ask_input "Enter MongoDB URI (mongodb+srv://...)")

# Create config file
echo -e "${YELLOW}Creating config file...${NC}"
cp config_sample.py config.py

# Update the config file with provided values
echo -e "${YELLOW}Updating config file with your values...${NC}"
sed -i "s/BOT_TOKEN = \".*\"/BOT_TOKEN = \"$BOT_TOKEN\"/" config.py
sed -i "s/OWNER_ID = .*$/OWNER_ID = $OWNER_ID/" config.py
sed -i "s/TELEGRAM_API = .*$/TELEGRAM_API = $TELEGRAM_API/" config.py
sed -i "s/TELEGRAM_HASH = \".*\"/TELEGRAM_HASH = \"$TELEGRAM_HASH\"/" config.py
sed -i "s|DATABASE_URL = \".*\"|DATABASE_URL = \"$DATABASE_URL\"|" config.py
sed -i "s/AUTHORIZED_CHATS = \".*\"/AUTHORIZED_CHATS = \"$OWNER_ID\"/" config.py
sed -i "s/WEB_PINCODE = .*$/WEB_PINCODE = True/" config.py

# Create custom docker-compose.yml file using volumes instead of building
echo -e "${YELLOW}Creating docker-compose.yml file...${NC}"
cat > docker-compose.yml << EOL
services:
  app:
    image: anasty17/mltb:latest
    container_name: mirror-bot
    command: bash start.sh
    restart: always
    network_mode: "host"
    volumes:
      - ./config.py:/usr/src/app/config.py
      - ./:/usr/src/app
EOL

# Pull and start the container
echo -e "${YELLOW}Pulling and starting the bot container...${NC}"
docker pull anasty17/mltb:latest
docker compose up -d

# Configure firewall for private use
echo -e "${YELLOW}Configuring firewall for private use...${NC}"
# Allow SSH and block external web access
iptables -F
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# Save iptables rules
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "${GREEN}The bot is now running in the background.${NC}"
echo -e "${BLUE}PRIVATE USE CONFIGURATION ENABLED${NC}"

echo -e "${GREEN}Bot Management:${NC}"
echo -e "${YELLOW}You can check if the bot is running with: docker ps${NC}"
echo -e "${YELLOW}You can view logs using: cd /opt/mirror-leech-bot && docker logs -f mirror-bot${NC}"
echo -e "${YELLOW}To stop the bot: cd /opt/mirror-leech-bot && docker compose stop${NC}"
echo -e "${YELLOW}To start the bot again: cd /opt/mirror-leech-bot && docker compose start${NC}"
echo -e "${YELLOW}To restart the bot: cd /opt/mirror-leech-bot && docker compose restart${NC}"
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}Your bot is configured for PRIVATE USE - only your Telegram ID ($OWNER_ID) can access it!${NC}"
echo -e "${BLUE}You can now use /leech command in Telegram to download files directly to Telegram.${NC}"
