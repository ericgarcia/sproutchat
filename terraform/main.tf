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

variable "availability_zone" {
  description = "The availability zone to deploy resources into."
  type        = string
  default     = "us-east-1a"
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

data "aws_caller_identity" "current" {}

# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }

  filter {
    name   = "availabilityZone"
    values = [var.availability_zone]
  }
}

# Define Security Group for SSH Access
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

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

# # Add new IAM policy for DescribeAvailabilityZones
# resource "aws_iam_role_policy" "describe_az_policy" {
#   name = "describe-az-policy"
#   role = aws_iam_role.ec2_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:DescribeAvailabilityZones"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

resource "aws_iam_policy" "eks_describe_cluster_policy" {
  name        = "eks-describe-cluster-policy"
  description = "Policy to allow describing EKS clusters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "arn:aws:eks:us-east-1:${data.aws_caller_identity.current.account_id}:cluster/ray-cluster"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_eks_describe_cluster_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.eks_describe_cluster_policy.arn
}

# resource "aws_iam_role_policy_attachment" "attach_describe_az_policy" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = aws_iam_role_policy.describe_az_policy.arn
# }

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# Create or Import Key Pair
resource "aws_key_pair" "my_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Module to directly launch an instance without AMI creation
module "base_instance" {
  source               = "./modules/base_instance"
  key_name             = aws_key_pair.my_key.key_name
  subnet_id            = data.aws_subnet.default.id
  security_group_id    = aws_security_group.ssh_access.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  private_key_path     = var.private_key_path
  base_ami             = var.base_ami
  python_version       = file("${path.module}/../.python-version")
  git_user_email       = var.git_user_email
  git_user_name        = var.git_user_name
}

# Module to build the AMI
module "build_ami" {
  source           = "./modules/build_ami"
  base_instance_id = module.base_instance.instance_id
  ami_version      = var.ami_version

  depends_on = [module.base_instance]
}

# Module to deploy the instance using the custom AMI
module "ami_instance" {
  source               = "./modules/ami_instance"
  ami_id               = module.build_ami.custom_ami_id
  key_name             = aws_key_pair.my_key.key_name
  subnet_id            = data.aws_subnet.default.id
  security_group_id    = aws_security_group.ssh_access.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  depends_on = [module.build_ami]
}

# Expose ami_instance module outputs at the root level
output "ami_instance_id" {
  value = module.ami_instance.instance_id
}

output "ami_instance_public_ip" {
  value = module.ami_instance.public_ip
}

# Expose base_instance module outputs at the root level
output "base_instance_id" {
  value = module.base_instance.instance_id
}

output "base_instance_public_ip" {
  value = module.base_instance.public_ip
}
