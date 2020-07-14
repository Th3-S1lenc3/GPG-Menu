#!/bin/bash

# Checks if script is running as root
if [ "$EUID" != 0 ]; then
  echo "Please run as root"
  exit
fi

# Update and install dependencies
echo "Updating and installing dependencies..."
apt update
apt -y upgrade
cat dependencies | xargs apt install -y

# Configure Firewall
echo "Block Internet Access To Machine? [Recommended] [Y/n]: "
read -rp ":" CHOICE
CHOICE=$(echo $CHOICE | awk '{print tolower($0)}')
if [ $CHOICE = "y" ]; then
  ufw disable
  ufw default deny incoming
  ufw default deny outgoing
  ufw enable
fi

# Add to bin
chmod +x *.sh
echo "Adding gpg-menu to /bin..."
cp gpg-menu-init.sh /bin/gpg-menu

# Add files to /etc/gpg-menu/
echo "Moving files to /etc/gpg-menu..."
mkdir /etc/gpg-menu/
cp gpg-menu.sh dependencies New_Message.template preferences version LICENSE README.md /etc/gpg-menu

# Clean up
echo "Done."
