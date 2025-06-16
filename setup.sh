#!/bin/bash

# Simple setup script to download and run the mirror-leech-telegram-bot installer
# Created by GitHub Copilot

echo "====================================================="
echo "Mirror-Leech-Telegram-Bot Downloader Script"
echo "====================================================="
echo "This script will download and prepare the installer for the Telegram bot."
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if curl is installed
if ! command_exists curl; then
    echo "curl is not installed. Installing curl..."
    apt-get update
    apt-get install -y curl
fi

# Create a temporary directory
mkdir -p /tmp/mirror-bot-installer
cd /tmp/mirror-bot-installer

echo "Downloading the installer script..."
curl -O https://raw.githubusercontent.com/ghostoperative/mirror-bot-installer/main/install_mirror_bot.sh

if [ $? -ne 0 ]; then
    echo "Failed to download the installer script."
    echo "Please make sure the URL is correct and accessible."
    exit 1
fi

# Make the script executable
chmod +x install_mirror_bot.sh

echo "====================================================="
echo "The installer script has been downloaded successfully!"
echo "To run the installation, execute the following command:"
echo "sudo ./install_mirror_bot.sh"
echo "====================================================="
