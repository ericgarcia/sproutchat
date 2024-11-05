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

# Reboot to load the NVIDIA driver
sudo reboot

# Wait for the instance to reboot
sleep 60

# Install CUDA toolkit
sudo apt-get update
sudo apt-get install -y nvidia-cuda-toolkit

# Verify CUDA installation
cuda_version=$(nvcc --version)
echo "CUDA version: $cuda_version"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# Install Docker
sudo apt-get install -y docker.io
# Enable and start Docker service
sudo systemctl enable --now docker
# Add the current user to the Docker group
sudo usermod -aG docker ubuntu

# Optional: Install Docker Compose
sudo apt install -y docker-compose

# Log success message
echo "Script completed. Please log out and log back in for Docker group membership changes to take effect."

# Install pytorch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install transformers accelerate
