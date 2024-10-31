# Start with an official Ubuntu image
FROM mcr.microsoft.com/vscode/devcontainers/python:3.9

# Update and install essential packages
RUN apt-get update -y && \
    apt-get install -y curl jq wget unzip zsh docker.io docker-compose python3-pip

# Set Zsh as the default shell
RUN chsh -s $(which zsh) root

# Install Oh My Zsh for a customized Zsh experience
# RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" -s --unattended

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Install PyTorch and Hugging Face Transformers
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip3 install transformers accelerate

# Create workspace directory
RUN mkdir -p /home/ubuntu/code && chown root:root /home/ubuntu/code

# Final message
RUN echo "Setup complete. Docker image ready."
