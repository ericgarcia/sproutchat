output "instance_public_ip" {
  description = "Public IP address of the deployed instance."
  value       = aws_instance.sproutchat_devbox.public_ip
}

output "instance_id" {
  description = "ID of the deployed EC2 instance."
  value       = aws_instance.sproutchat_devbox.id
}
