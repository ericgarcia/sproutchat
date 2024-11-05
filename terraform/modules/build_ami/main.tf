variable "base_instance_id" {
  description = "The ID of the base instance to use for the AMI."
  type        = string
}

variable "ami_version" {
  description = "Version identifier for the AMI to force rebuilds when changed."
  type        = string
}

# Create an AMI from the configured instance after setup completion
resource "aws_ami_from_instance" "custom_ami" {
  name               = "custom-sproutchat-dev-ami-${var.ami_version}"
  source_instance_id = var.base_instance_id
}

# Commented out to keep the base instance for reuse
# # Terminate the base instance after creating the AMI
# resource "null_resource" "terminate_base_instance" {
#   depends_on = [aws_ami_from_instance.custom_ami]

#   provisioner "local-exec" {
#     command = "aws ec2 terminate-instances --instance-ids ${var.base_instance_id}"
#   }
# }

output "custom_ami_id" {
  description = "ID of the created custom AMI."
  value       = aws_ami_from_instance.custom_ami.id
}
