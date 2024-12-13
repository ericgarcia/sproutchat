variable "key_name" {
  description = "The name of the existing key pair to use for SSH access to the EC2 instance."
  type        = string
}

variable "git_user_email" {
  description = "The email address to use for Git configuration."
  type        = string
}

variable "git_user_name" {
  description = "The name to use for Git configuration."
  type        = string
}

variable "public_key_path" {
  description = "Path to the SSH public key file."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to the SSH private key file."
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "ami_version" {
  description = "Version identifier for the AMI to force rebuilds when changed."
  type        = string
  default     = "v1.2" # Update to rebuild the AMI
}

variable "base_ami" {
  description = "The base AMI ID to use for the temporary instance in build_ami and base_instance."
  type        = string
  default     = "ami-0aada1758622f91bb" # Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.4 (Ubuntu 22.04)
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "ray-cluster-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required tags for EKS
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/ray-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/ray-cluster" = "shared"
  }
}

# Define Security Group for SSH Access
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cluster_access" {
  name        = "cluster_access"
  description = "Allow communication between the development instance and EKS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow all traffic from development instance"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.ssh_access.id]
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

resource "aws_iam_policy" "eks_full_access_policy" {
  name        = "eks-full-access-policy"
  description = "Policy to allow full access to EKS clusters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:AccessKubernetesApi"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_eks_full_access_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.eks_full_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_ec2_instance_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "attach_ec2_cni_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSCNIPolicy"
}

resource "aws_iam_role_policy_attachment" "attach_ec2_registry_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# Create or Import Key Pair
resource "aws_key_pair" "my_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# EKS Module
module "eks" {
  source                         = "./modules/eks"
  cluster_name                   = "ray-cluster"
  cluster_version                = "1.28"
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  ec2_instance_role_arn          = aws_iam_role.ec2_role.arn
}

# Module to directly launch an instance without AMI creation
module "base_instance" {
  source               = "./modules/base_instance"
  key_name             = aws_key_pair.my_key.key_name
  subnet_id            = module.vpc.private_subnets[0] # Use the first private subnet
  security_group_id    = aws_security_group.ssh_access.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  private_key_path     = var.private_key_path
  base_ami             = var.base_ami
  python_version       = file("${path.module}/../.python-version")
  git_user_email       = var.git_user_email
  git_user_name        = var.git_user_name
}

# Expose subnet IDs for debugging (Optional)
output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

# Expose base_instance module outputs at the root level
output "base_instance_id" {
  value = module.base_instance.instance_id
}

output "base_instance_public_ip" {
  value = module.base_instance.public_ip
}
