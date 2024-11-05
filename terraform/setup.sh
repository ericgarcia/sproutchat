#!/bin/bash

echo "Starting setup script..."

# Wait for dpkg lock to be released
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for dpkg lock to be released..."
    sleep 5
done

# Install Zsh
echo "Installing Zsh..."
sudo apt-get update
sudo apt-get install -y zsh
echo "Zsh installed."

# Install Oh My Zsh without prompts
echo "Installing Oh My Zsh..."
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "Oh My Zsh installed."

# Set zsh as the default shell for the user (if not already done)
sudo chsh -s $(which zsh) ubuntu

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

echo "Setup completed successfully."
touch /home/ubuntu/setup_complete
