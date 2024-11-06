variable "key_name" {
  description = "The name of the existing key pair for SSH access."
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID for the instance."
  type        = string
}

variable "security_group_id" {
  description = "Security group for SSH access."
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile for EC2."
  type        = string
}

variable "private_key_path" {
  description = "Path to the SSH private key."
  type        = string
}

variable "base_ami" {
  description = "The base AMI ID to use for the instance."
  type        = string
}

variable "python_version" {
  description = "The Python version to install using pyenv."
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

# Define the EC2 instance to configure directly
resource "aws_instance" "base_instance" {
  ami           = var.base_ami
  instance_type = "r5d.large"
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile

  tags = {
    Name = "BaseDevInstance"
  }

  # Configure the root EBS volume
  root_block_device {
    volume_size = 250   # Size in GB
    volume_type = "gp3" # General Purpose SSD
    # delete_on_termination = false # Persist root volume after termination
  }

  provisioner "file" {
    source      = "${path.root}/setup.sh"
    destination = "/home/ubuntu/setup.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup.sh",
      "/home/ubuntu/setup.sh -p \"${var.python_version}\" -u \"${var.git_user_name}\" -e \"${var.git_user_email}\" 2>&1 | tee -a /home/ubuntu/setup.log"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /home/ubuntu/setup_complete ]; do sleep 10; done"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

# Output the public IP and instance ID
output "instance_id" {
  description = "ID of the created EC2 instance."
  value       = aws_instance.base_instance.id
}

output "public_ip" {
  description = "Public IP of the created EC2 instance."
  value       = aws_instance.base_instance.public_ip
}
