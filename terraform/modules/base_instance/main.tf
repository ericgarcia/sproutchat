variable "key_name" {
  description = "The name of the existing key pair for SSH access."
  type        = string
}

variable "security_group" {
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

# Define the EC2 instance to configure directly
resource "aws_instance" "base_instance" {
  ami           = var.base_ami
  instance_type = "r5d.large"
  key_name      = var.key_name

  security_groups      = [var.security_group]
  iam_instance_profile = var.iam_instance_profile

  tags = {
    Name = "BaseInstance"
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
      "/home/ubuntu/setup.sh ${var.python_version} | tee -a /home/ubuntu/setup.log"
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
