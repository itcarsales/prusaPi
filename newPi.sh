#!/bin/bash
# Octoprint newPi - Raspberry Pi Initialization Script
# by Nick Haley

if ! [ $(id -u) -ne 0 ]; then
	echo "Setup cannot be run with sudo"
	exit 1
fi

echo && read -p "Would you like to initialize you raspberry pi? (y/n)" -n 1 -r -s installRPI && echo
if [[ $installRPI != "Y" && $installRPI != "y" ]]; then
	echo "newPi install cancelled."
	exit 1
fi

# Set Hostname
rHostname="prusaPi"
sudo raspi-config nonint do_hostname $rHostname

# Set Password
(echo "raspberry" ; echo "prusamaker" ; echo "prusamaker") | passwd

# Select Location
sudo dpkg-reconfigure locales

# Select Timezone
sudo dpkg-reconfigure tzdata

# Set GUI and Autologin
sudo raspi-config nonint do_boot_behaviour B2

# Disable Splash Screen on Boot
sudo raspi-config nonint do_boot_splash 1

# Enable SSH Server
sudo raspi-config nonint do_ssh 0

# raspi-config settings
echo 'Adding custom boot settings for Camera'
echo \# Custom Settings | sudo tee -a /boot/config.txt
echo gpu_mem=128 | sudo tee -a /boot/config.txt
echo start_x=1 | sudo tee -a /boot/config.txt

# Expand File System
sudo raspi-config --expand-rootfs
echo "File System expanded"

# COMPLETE - Reboot
echo "Your new password is prusamaker - please change after reboot"
echo "Complete: Rebooting Now"
sudo reboot now
exit 0
