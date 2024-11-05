#!/bin/bash

# Check if a Python version argument is provided
if [ -z "$1" ]; then
    echo "Error: No Python version provided."
    exit 1
fi

PYTHON_VERSION=$1

# Install Pyenv dependencies
echo "Installing Pyenv dependencies..."
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
                        libbz2-dev libreadline-dev libsqlite3-dev wget \
                        curl llvm libncurses5-dev libncursesw5-dev \
                        xz-utils tk-dev libffi-dev liblzma-dev \
                        python-openssl git

# Install Pyenv
echo "Installing Pyenv..."
curl https://pyenv.run | bash

# Configure .zshrc for Pyenv and other settings
echo "Configuring .zshrc..."
cat << 'EOF' >> /home/ubuntu/.zshrc

# Load pyenv automatically
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Customize Oh My Zsh theme (optional)
ZSH_THEME="robbyrussell"  # Choose a theme or replace with your preferred theme
EOF

# Set ownership for .zshrc if running as root
chown ubuntu:ubuntu /home/ubuntu/.zshrc

# Install Python and create a virtual environment with pyenv
echo "Installing Python $PYTHON_VERSION with pyenv..."
sudo -u ubuntu /home/ubuntu/.pyenv/bin/pyenv install $PYTHON_VERSION
echo "Creating virtual environment for sproutchat..."
sudo -u ubuntu /home/ubuntu/.pyenv/bin/pyenv virtualenv $PYTHON_VERSION sproutchat-env
sudo -u ubuntu /home/ubuntu/.pyenv/bin/pyenv activate sproutchat-env

echo "Setup completed successfully."
touch /home/ubuntu/setup_complete