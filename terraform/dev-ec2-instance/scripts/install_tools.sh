#!/bin/bash
# Update package manager
sudo apt-get update -y

# Install curl and jq if needed
sudo apt-get install -y curl jq

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Optional: Install other tools here
# Example: Installing AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# Install Docker
sudo apt-get install -y docker.io
# Enable Docker service
sudo systemctl start docker
sudo systemctl enable docker
# Add user to the Docker group
sudo usermod -aG docker ubuntu
# Optionally, install Docker Compose
sudo apt install -y docker-compose