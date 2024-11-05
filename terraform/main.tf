provider "aws" {
  region = var.region
}

# Define Security Group for SSH Access
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
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

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# Create or Import Key Pair
resource "aws_key_pair" "my_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Module to build the AMI
module "build_ami" {
  source               = "./modules/build_ami"
  key_name             = aws_key_pair.my_key.key_name
  security_group       = aws_security_group.ssh_access.name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  private_key_path     = var.private_key_path
  ami_version          = var.ami_version
  base_ami             = var.base_ami
}

# Module to deploy the instance using the custom AMI
module "deploy_instance" {
  source               = "./modules/deploy_instance"
  ami_id               = module.build_ami.custom_ami_id
  key_name             = aws_key_pair.my_key.key_name
  security_group       = aws_security_group.ssh_access.name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  depends_on = [module.build_ami]
}

# Output the instance's public IP and ID
output "instance_public_ip" {
  value = module.deploy_instance.instance_public_ip
}

output "instance_id" {
  value = module.deploy_instance.instance_id
}
