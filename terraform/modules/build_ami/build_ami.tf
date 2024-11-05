# Define the EC2 instance to configure the base image
resource "aws_instance" "base_instance" {
  ami                  = var.base_ami
  instance_type        = "r5d.large"
  key_name             = var.key_name
  security_groups      = [var.security_group]
  iam_instance_profile = var.iam_instance_profile

  tags = {
    Name = "BaseInstanceForAMI"
  }

  # Load the setup script from an external file as user data
  user_data = file("${path.module}/setup_user_data.sh")
}

# Wait for the setup to complete, indicated by the presence of a specific file
resource "null_resource" "wait_for_setup" {
  depends_on = [aws_instance.base_instance]

  # This provisioner waits until the setup_complete file is created by setup_user_data.sh
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /home/ubuntu/setup_complete ]; do sleep 10; done"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.base_instance.public_ip
      timeout     = "10m"
    }
  }
}

# Create an AMI from the configured instance after setup completion
resource "aws_ami_from_instance" "custom_ami" {
  name               = "custom-sproutchat-dev-ami-${var.ami_version}"
  source_instance_id = aws_instance.base_instance.id
  depends_on         = [null_resource.wait_for_setup]
}

# Terminate the base instance after creating the AMI
resource "null_resource" "terminate_base_instance" {
  depends_on = [aws_ami_from_instance.custom_ami]

  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.base_instance.id}"
  }
}
