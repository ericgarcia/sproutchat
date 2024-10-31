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


resource "aws_instance" "base_instance" {
  ami           = "ami-0aada1758622f91bb" # Replace with the desired base AMI ID
  instance_type = "r5d.large"
  key_name      = var.key_name

  # Attach security group and IAM instance profile
  security_groups      = [aws_security_group.ssh_access.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "BaseInstance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-pip",
      "sudo apt-get install -y nvidia-cuda-toolkit"
      # Add any other installation commands here
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu" # Adjust based on your AMI
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

resource "aws_ami_from_instance" "custom_ami" {
  name               = "custom-ami"
  source_instance_id = aws_instance.base_instance.id
  depends_on         = [aws_instance.base_instance]

  tags = {
    Name = "CustomAMI"
  }
}

resource "aws_instance" "sproutchat_devbox" {
  ami           = aws_ami_from_instance.custom_ami.id
  instance_type = "r5d.large"
  key_name      = var.key_name

  # Attach security group and IAM instance profile
  security_groups      = [aws_security_group.ssh_access.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "DevContainerInstance"
  }

  # No need for user_data script since the AMI has everything pre-installed
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
