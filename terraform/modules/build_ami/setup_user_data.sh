#!/bin/bash
echo "Starting setup script..." | tee /home/ubuntu/setup.log

# Wait for dpkg lock to be released
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for dpkg lock to be released..." | tee -a /home/ubuntu/setup.log
    sleep 5
done

echo "Installing Docker..." | tee -a /home/ubuntu/setup.log
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
echo "Docker installed." | tee -a /home/ubuntu/setup.log

echo "Installing AWS CLI..." | tee -a /home/ubuntu/setup.log
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws
echo "AWS CLI installed." | tee -a /home/ubuntu/setup.log

# Install PyTorch
echo "Installing PyTorch..." | tee -a /home/ubuntu/setup.log
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
python -c "import torch; print('CUDA is available' if torch.cuda.is_available() else 'CUDA is not available')" | tee -a /home/ubuntu/setup.log
echo "PyTorch installed." | tee -a /home/ubuntu/setup.log

# Check for completion and signal success
echo "Setup completed successfully." | tee -a /home/ubuntu/setup.log
touch /home/ubuntu/setup_complete
