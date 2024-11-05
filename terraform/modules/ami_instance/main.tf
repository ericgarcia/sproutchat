variable "ami_id" {
  description = "ID of the custom AMI to deploy."
  type        = string
}

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

# Deploy EC2 instance using the custom AMI
resource "aws_instance" "ami_dev_instance" {
  ami                  = var.ami_id
  instance_type        = "r5d.large"
  key_name             = var.key_name
  security_groups      = [var.security_group]
  iam_instance_profile = var.iam_instance_profile

  tags = {
    Name = "AMIDevInstance"
  }
}

# Output the public IP and instance ID
output "instance_id" {
  description = "ID of the created EC2 instance."
  value       = aws_instance.ami_dev_instance.id
}

output "public_ip" {
  description = "Public IP of the created EC2 instance."
  value       = aws_instance.ami_dev_instance.public_ip
}
