#!/bin/bash

echo "Starting setup script..."

# Function to display usage
usage() {
    echo "Invalid arguments provided: $*"
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

# Install AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install eksctl
echo "Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Helm
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# # Create EKS cluster with GPU nodes
# echo "Creating EKS cluster..."
# eksctl create cluster \
#     --name ray-cluster \
#     --region us-east-1 \
#     --nodes 2 \
#     --node-type g4dn.xlarge \
#     --with-oidc \
#     --ssh-access \
#     --ssh-public-key ~/.ssh/id_rsa.pub \
#     --managed

# # Install NVIDIA device plugin
# kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml

# Install Ray operator
echo "Installing Ray operator..."
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
helm install kuberay-operator kuberay/kuberay-operator

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

# Install Python and create a virtual environment with pyenv
echo "Installing Python $PYTHON_VERSION with pyenv..."
sudo -u ubuntu /home/ubuntu/.pyenv/bin/pyenv install $PYTHON_VERSION

# Set GitHub identity
git config --global user.email "$GIT_USER_NAME"
git config --global user.name "$GIT_USER_EMAIL"

# Install Kubernetes tools
echo "Installing Kubernetes tools..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "$(kubectl version --client)"
echo "Kubernetes tools installed."

echo "Setup completed successfully."
touch /home/ubuntu/setup_complete