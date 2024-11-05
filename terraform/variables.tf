variable "key_name" {
  description = "The name of the existing key pair to use for SSH access to the EC2 instance."
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
  default     = "v1" # Update to rebuild the AMI
}

variable "base_ami" {
  description = "The base AMI ID to use for the temporary instance in build_ami."
  type        = string
  default     = "ami-0aada1758622f91bb" # Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.4 (Ubuntu 22.04)
}
