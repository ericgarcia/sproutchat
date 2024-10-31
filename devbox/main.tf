# Variables for Key Pair Name and Public Key Path
variable "key_name" {
  description = "The name of the existing key pair to use for SSH access to the EC2 instance."
  type        = string
}

variable "public_key_path" {
  description = "Path to the SSH public key file."
  type        = string
  default     = "~/.ssh/id_rsa.pub" # Default path; users can override this in terraform.tfvars
}

provider "aws" {
  region = "us-east-1"
}

# Key Pair (Create if needed)
resource "aws_key_pair" "my_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Security Group for SSH access
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to all IPs; restrict as needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role for EC2 with Default Managed Policies
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
resource "aws_instance" "sproutchat_devbox" {
  ami = "ami-0aada1758622f91bb" # Replace with the desired AMI ID
  # instance_type = "t3.micro" # Tiny test instance
  instance_type = "r5d.large" # Intel-based, memory-optimized with 75 GB NVMe SSD 
  key_name      = var.key_name

  # Attach security group and IAM instance profile
  security_groups      = [aws_security_group.ssh_access.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "DevContainerInstance"
  }

  # Docker setup script
  user_data = file("${path.module}/install_tools.sh")
}

# Output the instance's public IP
output "instance_public_ip" {
  value = aws_instance.sproutchat_devbox.public_ip
}

# Output the instance's ID
output "instance_id" {
  value       = aws_instance.sproutchat_devbox.id
  description = "The ID of the EC2 instance"
}

