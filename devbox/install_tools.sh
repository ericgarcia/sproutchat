#!/bin/bash
# Update package manager
sudo apt-get update -y

# Install essential packages
sudo apt-get install -y curl jq wget unzip

# Install Zsh
sudo apt install -y zsh

# Set Zsh as the default shell for the current user (run under root)
chsh -s $(which zsh) ubuntu || echo "Failed to change shell to Zsh"

# Install Oh My Zsh for a customized Zsh experience (unattended installation)
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" -s --unattended

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
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

# # Install pytorch
# pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
# pip install transformers accelerate

# Create workspace directory
mkdir -p /home/ubuntu/code
chown ubuntu:ubuntu /home/ubuntu/code
