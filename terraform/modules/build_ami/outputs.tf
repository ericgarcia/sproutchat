output "custom_ami_id" {
  description = "ID of the created custom AMI."
  value       = aws_ami_from_instance.custom_ami.id
}
