# EC2 Instance Setup with Terraform, IAM Roles, and SSH Access

This guide provides a step-by-step walkthrough for setting up an EC2 instance with Terraform, attaching default AWS-managed IAM roles for access to AWS services, and connecting to the instance via SSH. It also includes troubleshooting steps to resolve common SSH access issues.

---

## Prerequisites

- **AWS CLI**: Install and configure the AWS CLI with your credentials.
- **Terraform**: Install Terraform on your local machine.
- **SSH Key Pair**: You need a valid SSH key pair (e.g., `id_rsa` and `id_rsa.pub`) for SSH access to the instance.

---

## Step 1: Create a Terraform Configuration File

Create a new `.tf` file (e.g., `main.tf`) with the following configuration. This file defines resources to:

- Set up an EC2 instance.
- Attach a security group for SSH access.
- Use default IAM roles for EC2 management, EKS cluster creation, and read-only access to S3.

### Terraform Configuration File (`main.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

# Key Pair (Create if needed)
resource "aws_key_pair" "my_key" {
  key_name   = "ericg-odell"
  public_key = file("~/.ssh/id_rsa.pub")  # Path to your local SSH public key
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

# IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "EC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach Default AWS Policies to the Role

# AmazonS3ReadOnlyAccess for read-only access to S3
resource "aws_iam_role_policy_attachment" "s3_readonly_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# EKS Managed Policies for EKS Cluster management
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# AmazonEC2ContainerRegistryFullAccess for ECR Access
resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# Create an Instance Profile for the Role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance
resource "aws_instance" "dev_container_instance" {
  ami           = "ami-0aada1758622f91bb"  # Replace with the desired AMI ID
  instance_type = "t3.micro"
  key_name      = aws_key_pair.my_key.key_name

  # Attach security group and IAM instance profile
  security_groups      = [aws_security_group.ssh_access.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "DevContainerInstance"
  }
}

# Output the instance's public IP
output "instance_public_ip" {
  value = aws_instance.dev_container_instance.public_ip
}

# Output the instance's ID
output "instance_id" {
  value = aws_instance.dev_container_instance.id
  description = "The ID of the EC2 instance"
}
```

### Explanation of the IAM Policies

- **AmazonS3ReadOnlyAccess**: Provides read-only access to S3, useful for instances that retrieve data from S3.
- **AmazonEKSClusterPolicy** and **AmazonEKSServicePolicy**: Allow creation and management of EKS clusters.
- **AmazonEC2ContainerRegistryFullAccess**: Grants access to Amazon ECR for pulling and pushing container images.

---

## Step 2: Deploy the Terraform Configuration

1. **Initialize Terraform**: Run this command to initialize your Terraform workspace.
   ```bash
   terraform init
   ```

2. **Apply the Configuration**: Run this command to deploy the resources defined in the configuration file.
   ```bash
   terraform apply
   ```
   Confirm the plan by typing `yes` when prompted. After a successful run, Terraform will output the public IP of the instance.

---

## Step 3: SSH into the EC2 Instance

After deploying the instance, you can SSH into it using the public IP provided by Terraform.

1. Retrieve the public IP of the instance:
   ```bash
   terraform output instance_public_ip
   ```

2. SSH into the instance with the following command, replacing `<public_ip>` with the instance’s public IP and `<path-to-private-key>` with the path to your private key file:
   ```bash
   ssh -i <path-to-private-key> ec2-user@<public_ip>
   ```

   For example:
   ```bash
   ssh -i ~/.ssh/id_rsa ec2-user@34.201.45.56
   ```

3. **Username Notes**:
   - **Amazon Linux**: Use `ec2-user`.
   - **Ubuntu**: Use `ubuntu`.

---

## Troubleshooting SSH Access

If you are unable to SSH into the instance, use these troubleshooting steps:

### 1. Ensure Correct Private Key Permissions

The private key file must have restricted permissions. Use:
```bash
chmod 400 ~/.ssh/id_rsa
```

### 2. Check Security Group Rules

Ensure the security group associated with the instance allows inbound SSH traffic (port 22) from your IP address.

You can verify this in the **EC2 Console**:
- Navigate to **EC2 Dashboard** > **Security Groups**.
- Find your security group and check **Inbound rules**.
- Confirm there is a rule allowing TCP on port 22 with `0.0.0.0/0` (or restrict to your IP).

### 3. Verify the Instance State

Make sure your instance is in the `running` state. You can check this with:
```bash
aws ec2 describe-instances --instance-ids <instance_id> --query "Reservations[*].Instances[*].State.Name" --output text
```

### 4. Confirm Correct Public IP Address

Ensure the public IP you’re using matches the one output by Terraform.

---

## Additional Notes

- **IAM Role Management**: Attaching the `AmazonEC2RoleforSSM` role enables management of the instance via AWS Systems Manager, reducing the need for SSH access in production environments.
- **Security Best Practices**: Consider restricting SSH access to specific IPs in the security group instead of `0.0.0.0/0`, which allows access from all IP addresses.

---

This completes the setup and access instructions for your EC2 instance using Terraform and AWS-managed IAM policies.
