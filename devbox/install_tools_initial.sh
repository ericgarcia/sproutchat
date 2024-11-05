#!/bin/bash

# Function to wait for the dpkg lock to be released
wait_for_dpkg_lock() {
    while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        echo "Waiting for dpkg lock to be released..."
        sleep 5
    done
}

# Wait for dpkg lock to be released
wait_for_dpkg_lock

# Add NVIDIA package repositories
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt-get update

# Install NVIDIA driver
sudo apt-get install -y nvidia-driver-470

# Schedule the next script to run after reboot
echo "@reboot root /home/ubuntu/install_tools_post_reboot.sh" | sudo tee -a /etc/crontab

# Reboot to load the NVIDIA driver
sudo reboot
