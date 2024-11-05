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

# Define the EC2 instance to configure directly
resource "aws_instance" "base_instance" {
  ami                         = var.base_ami
  instance_type               = "r5d.large"
  key_name                    = var.key_name
  security_groups             = [var.security_group]
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = true

  tags = {
    Name = "BaseDevInstance"
  }
}

# Upload and run setup script using remote-exec
resource "null_resource" "run_setup_script" {
  depends_on = [aws_instance.base_instance]

  # Upload the setup script to the instance
  provisioner "file" {
    source      = "${path.root}/setup.sh"
    destination = "/home/ubuntu/setup.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.base_instance.public_ip
    }
  }

  # Execute the setup script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup.sh",
      "/home/ubuntu/setup.sh | tee -a /home/ubuntu/setup.log"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.base_instance.public_ip
    }
  }

  # Upload the requirements.txt file from one directory above the Terraform root directory
  provisioner "file" {
    source      = "${path.root}/../requirements.txt"
    destination = "/home/ubuntu/requirements.txt"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.base_instance.public_ip
    }
  }

  # Run pip to install the packages from requirements.txt
  provisioner "remote-exec" {
    inline = [
      "pip install -r /home/ubuntu/requirements.txt"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.base_instance.public_ip
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
