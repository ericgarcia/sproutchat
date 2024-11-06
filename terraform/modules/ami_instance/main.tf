variable "ami_id" {
  description = "ID of the custom AMI to deploy."
  type        = string
}

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

# Deploy EC2 instance using the custom AMI
resource "aws_instance" "ami_instance" {
  ami           = var.ami_id
  instance_type = "r5d.large"
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile

  tags = {
    Name = "AMIDevInstance"
  }
}

# Output the public IP and instance ID
output "instance_id" {
  description = "ID of the created EC2 instance."
  value       = aws_instance.ami_instance.id
}

output "public_ip" {
  description = "Public IP of the created EC2 instance."
  value       = aws_instance.ami_instance.public_ip
}
