#!/bin/bash

echo "Starting setup script..."

# Function to display usage
usage() {
    echo "Usage: $0 -p <python_version> -u <git_user_name> -e <git_user_email>"
    exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--python) PYTHON_VERSION="$2"; shift ;;
        -u|--user) GIT_USER_NAME="$2"; shift ;;
        -e|--email) GIT_USER_EMAIL="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Check if all required arguments are provided
if [ -z "$PYTHON_VERSION" ] || [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
    usage
fi

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
                        python-openssl git python3.12-dev

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

# Install direnv
sudo apt install direnv

# Install Python and create a virtual environment with pyenv
echo "Installing Python $PYTHON_VERSION with pyenv..."
sudo -u ubuntu /home/ubuntu/.pyenv/bin/pyenv install $PYTHON_VERSION

# Set GitHub identity
git config --global user.email "$GIT_USER_NAME"
git config --global user.name "$GIT_USER_EMAIL"

echo "Setup completed successfully."
touch /home/ubuntu/setup_complete