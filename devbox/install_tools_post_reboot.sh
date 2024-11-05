#!/bin/bash

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

# Create workspace directory
mkdir -p /home/ubuntu/code
chown ubuntu:ubuntu /home/ubuntu/code

# Remove the script from crontab
sudo sed -i '/install_tools_post_reboot.sh/d' /etc/crontab

# Create a completion file
touch /home/ubuntu/setup_complete