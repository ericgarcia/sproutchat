To create declarative infrastructure for launching and stopping an EC2 instance, you can use **AWS CloudFormation** or **Terraform**. Here’s how to do this using **Terraform** for simplicity and modularity.

### Step 1: Install Terraform

1. **Download Terraform**: [Terraform Install Guide](https://www.terraform.io/downloads)
2. Follow the instructions to add Terraform to your PATH.

### Step 2: Create a Terraform Configuration

In a new project folder, create a `.tf` file (e.g., `main.tf`) to define the infrastructure. This configuration will define an EC2 instance with the necessary settings to allow SSH access.

#### Example Terraform Configuration (main.tf)

```hcl
provider "aws" {
  region = "us-west-2"  # Replace with your preferred region
}

# Key Pair (Create if needed)
resource "aws_key_pair" "my_key" {
  key_name   = "my-key"
  public_key = file("~/.ssh/my-key.pub")  # Path to your local SSH public key
}

# Security Group for SSH access
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to all IPs; restrict as needed
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "dev_container_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI; replace with your preferred AMI ID
  instance_type = "t3.micro"               # Choose instance type based on your needs
  key_name      = aws_key_pair.my_key.key_name

  security_groups = [aws_security_group.ssh_access.name]

  tags = {
    Name = "DevContainerInstance"
  }
}

# Output the instance's public IP
output "instance_public_ip" {
  value = aws_instance.dev_container_instance.public_ip
}
```

### Step 3: Initialize and Apply the Terraform Configuration

1. **Initialize Terraform**:

   ```bash
   terraform init
   ```

2. **Apply the Configuration**:

   ```bash
   terraform apply
   ```

   Review the changes, then type `yes` to confirm. Terraform will launch the EC2 instance, create the security group, and output the instance’s public IP.

3. **Connect to the EC2 Instance**:

   After Terraform completes, copy the public IP output and use SSH to connect:

   ```bash
   ssh -i ~/.ssh/my-key.pem ec2-user@<instance_public_ip>
   ```

### Step 4: Stop and Start the EC2 Instance

You can use Terraform to stop and start instances declaratively with slight configuration adjustments. Here’s how:

#### Add a Variable for Instance State

1. Modify `main.tf` to add a `desired_state` variable and conditional stopping logic.

   ```hcl
   variable "desired_state" {
     type    = string
     default = "running"
     description = "Desired instance state, either 'running' or 'stopped'"
   }

   resource "aws_instance" "dev_container_instance" {
     ami           = "ami-0c55b159cbfafe1f0" 
     instance_type = "t3.micro"
     key_name      = aws_key_pair.my_key.key_name
     security_groups = [aws_security_group.ssh_access.name]

     tags = {
       Name = "DevContainerInstance"
     }

     # Start or stop the instance based on the variable
     lifecycle {
       prevent_destroy = true
     }
   }

   resource "aws_instance_state" "instance_state_control" {
     instance_id = aws_instance.dev_container_instance.id
     state       = var.desired_state
   }
   ```

2. To start or stop the instance, modify the `desired_state` variable in `terraform.tfvars`:

   ```hcl
   desired_state = "stopped"
   ```

3. Run `terraform apply` to update the instance's state based on the `desired_state` setting.

### Step 5: Clean Up the Resources

When you no longer need the EC2 instance, you can clean up everything using:

```bash
terraform destroy
```

This will stop the instance and delete all associated resources, ensuring no ongoing costs.

With this setup, you can declaratively manage the lifecycle of your EC2 instance using Terraform’s state-based infrastructure management. Adjustments to instance configurations, security groups, or SSH access are straightforward, and all changes are version-controlled.