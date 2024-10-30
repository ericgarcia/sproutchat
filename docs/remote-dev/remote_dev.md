# Configure an AWS EC2 instance to use **Remote - Containers** with VS Code.

### Step 1: Set Up an AWS EC2 Instance

1. **Launch an EC2 Instance**:
   - Go to the [AWS Management Console](https://aws.amazon.com/console/), navigate to **EC2**, and click **Launch Instance**.
   - Choose an **Amazon Machine Image (AMI)**, such as **Ubuntu 20.04 LTS**.
   - Select an instance type (e.g., `t3.medium` or higher for development).
   - Configure security groups to allow SSH (port 22).

2. **Configure the Instance for Docker**:
   - SSH into your EC2 instance:
     ```bash
     ssh -i /path/to/your-key.pem ec2-user@your-ec2-ip
     ```
   - Update the instance and install Docker:
     ```bash
     sudo apt update
     sudo apt install -y docker.io
     sudo systemctl start docker
     sudo systemctl enable docker
     ```
   - Add your user to the `docker` group to run Docker without `sudo`:
     ```bash
     sudo usermod -aG docker $USER
     ```
   - Log out and log back in to apply the group change.

3. **Install Docker Compose (Optional)**:
   If you plan to use `docker-compose`, install it as well:
   ```bash
   sudo apt install -y docker-compose
   ```

### Step 2: Install VS Code and Remote - Containers Extension

1. **Install the Remote - SSH and Remote - Containers Extension**:
   - Open **VS Code** on your local machine.
   - Go to the **Extensions** view (press `Ctrl+Shift+X`), search for **Remote - SSH** and **Remote - Containers**, and install both extensions.

2. **Configure SSH Access**:
   - Update your SSH config file (`~/.ssh/config`) to add your EC2 instance details:
     ```plaintext
     Host your-ec2-instance
         HostName ec2-xx-xx-xx-xx.compute-1.amazonaws.com
         User ec2-user  # or your instance's default user
         IdentityFile /path/to/your-key.pem
     ```
   - Test the SSH connection from your terminal:
     ```bash
     ssh your-ec2-instance
     ```

### Step 3: Configure VS Code Dev Container Setup

1. **Create a Dev Container Configuration**:
   - In your local project directory (where your code is stored), create a `.devcontainer` folder.
   - Inside `.devcontainer`, create a `devcontainer.json` file to define the container environment.

2. **Example `devcontainer.json` Configuration**:

   Here’s a sample configuration file for a Python development environment:

   ```json
    {
        "name": "Python Dev Container",
        "image": "python:3.9-slim",
        "postCreateCommand": "pip install -r requirements.txt",
        "remoteUser": "vscode",
        "features": {
        "ghcr.io/devcontainers/features/docker-in-docker:2": {}
        },
        "customizations": {
        "vscode": {
            "settings": {
            "terminal.integrated.shell.linux": "/bin/bash"
            }
        }
        },
        "mounts": [
        "source=${localWorkspaceFolder},target=/workspace,type=bind"
        ],
        "workspaceFolder": "/workspace"
    }
   ```

3. **Upload Your Project to the EC2 Instance**:
   - You can use `rsync` to sync your project directory with the EC2 instance:

     ```bash
     rsync -avz --exclude-from='.gitignore' ~/code/sproutchat/ dev-ec2-instance:~/code/sproutchat
     ```

### Step 4: Connect to EC2 and Open Dev Container in VS Code

1. **Connect to the Remote EC2 Instance via SSH in VS Code**:
   - In VS Code, press `F1` (or `Ctrl+Shift+P`), type **Remote-SSH: Connect to Host**, and select your EC2 instance from the list.
   - Open the project folder on the remote instance where your `.devcontainer` configuration is located.

2. **Open the Dev Container**:
   - Once connected to the EC2 instance, press `F1`, type **Remote-Containers: Reopen in Container**, and select it.
   - VS Code will read the `devcontainer.json` file and build the Docker container based on your configuration.

3. **Start Developing**:
   - Now you can edit files, run commands in the terminal, and execute code within the container on your remote EC2 instance, just as if you were working locally.

### Step 5: (Optional) Automate Container Setup

- To simplify future setups, you can use a `Dockerfile` or additional scripts in your `.devcontainer` configuration to automate installing dependencies, setting up environment variables, or configuring other tools.

### Additional Tips

- **Port Forwarding**: If your project includes a web app, you can forward ports (e.g., 8000) from the container to your local machine by setting `"forwardPorts": [8000]` in `devcontainer.json`.
- **Containerized Tools**: Consider using Docker images that contain pre-installed development tools to save setup time.

This setup enables you to use VS Code on a local machine while developing within a containerized environment on an EC2 instance, optimizing both flexibility and performance.