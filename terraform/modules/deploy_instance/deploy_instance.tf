# Deploy EC2 instance using the custom AMI
resource "aws_instance" "sproutchat_devbox" {
  ami                  = var.ami_id
  instance_type        = "r5d.large"
  key_name             = var.key_name
  security_groups      = [var.security_group]
  iam_instance_profile = var.iam_instance_profile

  tags = {
    Name = "SproutChatDevBox"
  }
}
