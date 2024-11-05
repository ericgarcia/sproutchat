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
