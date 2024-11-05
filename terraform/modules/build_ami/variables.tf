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

variable "ami_version" {
  description = "Version identifier for the AMI to force rebuilds when changed."
  type        = string
}

variable "base_ami" {
  description = "The base AMI ID to use for the temporary instance in build_ami."
  type        = string
}
