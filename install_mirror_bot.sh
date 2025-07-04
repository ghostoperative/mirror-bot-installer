#!/bin/bash

# Mirror-Leech-Telegram-Bot Installer Script for DigitalOcean
# Created by GitHub Copilot

# Set colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}Mirror-Leech-Telegram-Bot Installer for DigitalOcean${NC}"
echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}This script will install all necessary dependencies and set up the bot.${NC}"
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

# Install Docker using the official Docker installation script
echo -e "${YELLOW}Installing Docker using the official Docker script...${NC}"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
echo -e "${YELLOW}Installing Docker Compose...${NC}"
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Enable Docker service
echo -e "${YELLOW}Enabling Docker service...${NC}"
systemctl enable docker
systemctl start docker

# Verify Docker installation
echo -e "${YELLOW}Verifying Docker installation...${NC}"
docker --version
docker compose version

# Create directory for the bot
echo -e "${YELLOW}Creating directory for the bot...${NC}"
mkdir -p /opt/mirror-leech-bot
cd /opt/mirror-leech-bot

# Check if directory is empty before cloning
echo -e "${YELLOW}Preparing to clone repository...${NC}"
if [ "$(ls -A /opt/mirror-leech-bot)" ]; then
    echo -e "${YELLOW}Directory not empty. Checking if repo is already cloned...${NC}"
    if [ -f "/opt/mirror-leech-bot/config_sample.py" ]; then
        echo -e "${GREEN}Repository already exists. Updating...${NC}"
        git pull
    else
        echo -e "${RED}Directory not empty and doesn't look like our repository.${NC}"
        echo -e "${YELLOW}Please backup and remove contents or specify a different directory.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone https://github.com/anasty17/mirror-leech-telegram-bot .
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to clone repository. Check your internet connection.${NC}"
        exit 1
    fi
fi

# Install dependencies for command-line tools
echo -e "${YELLOW}Installing Python dependencies...${NC}"
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
apt install -y python3-venv python3-full
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements-cli.txt
echo -e "${GREEN}Python dependencies installed in virtual environment${NC}"

# Configure firewall for private use (only allow SSH and block external web access)
echo -e "${YELLOW}Configuring firewall for private use...${NC}"

# Flush All Rules (Reset iptables)
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ip6tables -F
ip6tables -X
ip6tables -t nat -F
ip6tables -t nat -X
ip6tables -t mangle -F
ip6tables -t mangle -X

# Set Default Policies
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

ip6tables -P INPUT DROP
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Block external access to web ports (80, 8080)
# Only allow localhost to access these ports
iptables -A INPUT -p tcp --dport 80 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 8090 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 8070 -s 127.0.0.1 -j ACCEPT

# Save iptables rules
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

echo -e "${GREEN}Firewall configured for private use - only SSH is accessible externally!${NC}"
echo -e "${YELLOW}Web interfaces will only be accessible via SSH tunneling${NC}"

# Create config file from sample
echo -e "${YELLOW}Creating config file...${NC}"
cp config_sample.py config.py

# Get bot configuration details from user
echo -e "${GREEN}Please provide the following details for bot configuration:${NC}"
echo -e "${YELLOW}You can find more information in the README file about each option${NC}"
echo -e "${BLUE}This installation is configured for PRIVATE USE ONLY${NC}"

BOT_TOKEN=$(ask_input "Enter Telegram Bot Token (from @BotFather)")
OWNER_ID=$(ask_input "Enter Telegram Owner ID (your user ID, not username)")
TELEGRAM_API=$(ask_input "Enter Telegram API ID (from my.telegram.org)")
TELEGRAM_HASH=$(ask_input "Enter Telegram API Hash (from my.telegram.org)")
DATABASE_URL=$(ask_input "Enter MongoDB URI (mongodb+srv://...)")

# For private use, we'll set BASE_URL to localhost by default
echo -e "${YELLOW}Setting up for private use - Web interface will only be accessible locally${NC}"
BASE_URL="http://localhost"
BASE_URL_PORT="80"
RCLONE_SERVE_URL="http://localhost"
RCLONE_SERVE_PORT="8080"
DEFAULT_UPLOAD=$(ask_input "Enter DEFAULT_UPLOAD (gd for Google Drive or rc for Rclone, default: rc)")

# Ask if the user wants to generate service accounts for Google Drive
echo -e "${YELLOW}Do you want to set up Service Accounts for Google Drive? (y/n)${NC}"
read use_service_accounts

# Ask if the user wants to set up Google Drive
echo -e "${YELLOW}Do you want to set up Google Drive? (y/n)${NC}"
read setup_gdrive

# Update the config file with provided values
echo -e "${YELLOW}Updating config file with your values...${NC}"
sed -i "s/BOT_TOKEN = \".*\"/BOT_TOKEN = \"$BOT_TOKEN\"/" config.py
sed -i "s/OWNER_ID = .*$/OWNER_ID = $OWNER_ID/" config.py
sed -i "s/TELEGRAM_API = .*$/TELEGRAM_API = $TELEGRAM_API/" config.py
sed -i "s/TELEGRAM_HASH = \".*\"/TELEGRAM_HASH = \"$TELEGRAM_HASH\"/" config.py
sed -i "s|DATABASE_URL = \".*\"|DATABASE_URL = \"$DATABASE_URL\"|" config.py
sed -i "s|BASE_URL = \".*\"|BASE_URL = \"$BASE_URL\"|" config.py
sed -i "s/BASE_URL_PORT = .*$/BASE_URL_PORT = $BASE_URL_PORT/" config.py
sed -i "s|RCLONE_SERVE_URL = \".*\"|RCLONE_SERVE_URL = \"$RCLONE_SERVE_URL\"|" config.py
sed -i "s/RCLONE_SERVE_PORT = .*$/RCLONE_SERVE_PORT = $RCLONE_SERVE_PORT/" config.py
sed -i "s/DEFAULT_UPLOAD = \".*\"/DEFAULT_UPLOAD = \"$DEFAULT_UPLOAD\"/" config.py

# Configure the bot for private use - set AUTHORIZED_CHATS to only your ID
sed -i "s/AUTHORIZED_CHATS = \".*\"/AUTHORIZED_CHATS = \"$OWNER_ID\"/" config.py

# Set additional security settings
echo -e "${YELLOW}Configuring additional security settings for private use...${NC}"
sed -i "s/WEB_PINCODE = .*$/WEB_PINCODE = True/" config.py

if [[ $setup_gdrive == "y" || $setup_gdrive == "Y" ]]; then
    echo -e "${YELLOW}Setting up Google Drive...${NC}"
    echo -e "${YELLOW}Please follow these steps to set up Google Drive:${NC}"
    echo -e "1. Visit https://console.developers.google.com/apis/credentials"
    echo -e "2. Create a project, configure OAuth consent screen"
    echo -e "3. Create Credentials -> OAuth Client ID -> Desktop app"
    echo -e "4. Download the credentials json file"
    echo -e "5. Rename it to credentials.json and place it in this directory"
    
    echo -e "${YELLOW}Press Enter when you have placed the credentials.json file in this directory...${NC}"
    read
    
    if [ -f "credentials.json" ]; then
        echo -e "${GREEN}credentials.json found!${NC}"
        echo -e "${YELLOW}Generating token.pickle file...${NC}"
        # Ensure we're using the virtual environment
        source venv/bin/activate
        pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
        python generate_drive_token.py

        echo -e "${YELLOW}Enter your Google Drive folder ID or TeamDrive ID:${NC}"
        read gdrive_id
        sed -i "s/GDRIVE_ID = \".*\"/GDRIVE_ID = \"$gdrive_id\"/" config.py
        
        echo -e "${YELLOW}Is this a Team Drive? (y/n)${NC}"
        read is_team_drive
        if [[ $is_team_drive == "y" || $is_team_drive == "Y" ]]; then
            sed -i "s/IS_TEAM_DRIVE = .*$/IS_TEAM_DRIVE = True/" config.py
        else
            sed -i "s/IS_TEAM_DRIVE = .*$/IS_TEAM_DRIVE = False/" config.py
        fi

        echo -e "${YELLOW}Enter your Drive Index URL (leave empty if none):${NC}"
        read index_url
        if [ ! -z "$index_url" ]; then
            sed -i "s|INDEX_URL = \".*\"|INDEX_URL = \"$index_url\"|" config.py
        fi
        
        if [[ $use_service_accounts == "y" || $use_service_accounts == "Y" ]]; then
            echo -e "${YELLOW}Setting up Service Accounts...${NC}"
            echo -e "${YELLOW}You can create service accounts using:${NC}"
            echo -e "python3 gen_sa_accounts.py --quick-setup 1 --new-only"
            echo -e "${YELLOW}Run this command after the installation is complete.${NC}"
            sed -i "s/USE_SERVICE_ACCOUNTS = .*$/USE_SERVICE_ACCOUNTS = True/" config.py
        fi
    else
        echo -e "${RED}credentials.json not found. Skipping Google Drive setup.${NC}"
    fi
fi

# Ask if the user wants to set up Rclone
echo -e "${YELLOW}Do you want to set up Rclone? (y/n)${NC}"
read setup_rclone

if [[ $setup_rclone == "y" || $setup_rclone == "Y" ]]; then
    echo -e "${YELLOW}Installing rclone...${NC}"
    curl https://rclone.org/install.sh | bash
    
    echo -e "${YELLOW}Please run 'rclone config' after this script completes to configure your remotes.${NC}"
    echo -e "${YELLOW}Enter your default Rclone path (format: remote:path):${NC}"
    read rclone_path
    sed -i "s|RCLONE_PATH = \".*\"|RCLONE_PATH = \"$rclone_path\"|" config.py
fi

echo -e "${GREEN}Configuration completed!${NC}"

# Build and start the Docker container
echo -e "${YELLOW}Building and starting the Docker container...${NC}"
cd /opt/mirror-leech-bot
docker compose version
echo -e "${YELLOW}Starting Docker container build...${NC}"

# Create a custom Dockerfile with DNS settings
echo -e "${YELLOW}Creating a customized Dockerfile with DNS settings...${NC}"
cp Dockerfile Dockerfile.original
cat > Dockerfile << EOL
FROM anasty17/mltb:latest

# Set DNS servers to fix connectivity issues
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf

WORKDIR /usr/src/app
RUN chmod 777 /usr/src/app

RUN python3 -m venv mltbenv

COPY requirements.txt .
RUN mltbenv/bin/pip install --no-cache-dir --timeout 100 -r requirements.txt

COPY . .

CMD ["bash", "start.sh"]
EOL

# Configure Docker daemon with reliable DNS
echo -e "${YELLOW}Configuring Docker daemon with reliable DNS servers...${NC}"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOL
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
EOL
systemctl restart docker

echo -e "${YELLOW}Starting Docker build with improved network settings...${NC}"
# Try with --network=host and DNS settings
if docker compose build --no-cache --network=host && docker compose up -d; then
    echo -e "${GREEN}Docker Compose build successful!${NC}"
else
    echo -e "${YELLOW}docker compose command failed, trying with docker-compose...${NC}"
    
    # Install docker-compose if not already installed
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Installing docker-compose...${NC}"
        curl -SL "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    if docker-compose build --no-cache --network=host && docker-compose up -d; then
        echo -e "${GREEN}Docker Compose build successful with docker-compose!${NC}"
    else
        echo -e "${RED}Build failed. Trying alternative approach...${NC}"
        
        echo -e "${YELLOW}Pulling pre-built image directly instead of building...${NC}"
        if docker pull anasty17/mltb:latest && docker compose up -d; then
            echo -e "${GREEN}Successfully started using pre-built image!${NC}"
        else
            echo -e "${RED}All attempts failed. Please check your internet connection and DNS settings.${NC}"
            exit 1
        fi
    fi
fi

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "${GREEN}The bot is now running in the background.${NC}"
echo -e "${BLUE}PRIVATE USE CONFIGURATION ENABLED${NC}"
echo -e "${YELLOW}Important: The web interfaces are only accessible locally for security${NC}"

echo -e "${GREEN}To access the web interfaces from your computer:${NC}"
echo -e "${YELLOW}Use SSH tunneling with the following commands from your local machine:${NC}"
echo -e "${BLUE}For qBittorrent web UI: ssh -L 8090:localhost:8090 username@your_server_ip${NC}"
echo -e "${BLUE}For general web interface: ssh -L 80:localhost:80 username@your_server_ip${NC}"
echo -e "${BLUE}For rclone web interface: ssh -L 8080:localhost:8080 username@your_server_ip${NC}"
echo -e "${YELLOW}Then access them via http://localhost:8090, http://localhost or http://localhost:8080 in your browser${NC}"

echo -e "${GREEN}Bot Management:${NC}"
echo -e "${YELLOW}You can check if the bot is running with: docker ps${NC}"
echo -e "${YELLOW}You can view logs using: cd /opt/mirror-leech-bot && docker compose logs --follow${NC}"
echo -e "${YELLOW}If docker compose doesn't work, try: docker-compose logs --follow${NC}"
echo -e "${YELLOW}To stop the bot: cd /opt/mirror-leech-bot && docker compose stop (or docker-compose stop)${NC}"
echo -e "${YELLOW}To start the bot again: cd /opt/mirror-leech-bot && docker compose start (or docker-compose start)${NC}"
echo -e "${YELLOW}To restart the bot: cd /opt/mirror-leech-bot && docker compose restart (or docker-compose restart)${NC}"
echo -e "${GREEN}=================================${NC}"
echo -e "${BLUE}See the README.md file for more details on usage and configuration.${NC}"
echo -e "${GREEN}Your bot is configured for PRIVATE USE - only your Telegram ID ($OWNER_ID) can access it!${NC}"
