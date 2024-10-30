You can manage the lifecycle of your EC2 instance (start, stop) and update your `.ssh/config` file with the instance’s IP address using Terraform and a shell script. Here’s a full guide to automate this process.

### 1. Start and Stop the Instance with Terraform

To control the EC2 instance state (start/stop) with Terraform, you’ll need to:
- Set up Terraform to create the instance initially.
- Use the `aws_instance` resource with an `instance_state` data source to retrieve and store the instance IP.
- Use a shell script to check the instance state and save the IP address to `.ssh/config`.

### Terraform Configuration (`main.tf`)

This configuration will create an EC2 instance and output the public IP. 

```hcl
provider "aws" {
  region = "us-east-1"
}

# Define the EC2 instance
resource "aws_instance" "my_instance" {
  ami           = "ami-0aada1758622f91bb"  # Replace with your desired AMI ID
  instance_type = "t3.micro"
  key_name      = var.key_name

  tags = {
    Name = "MyManagedInstance"
  }
}

# Output the instance's public IP address
output "instance_public_ip" {
  value       = aws_instance.my_instance.public_ip
  description = "The public IP address of the EC2 instance"
}
```

### Terraform Variables (`variables.tf`)

Define any necessary variables for the key pair and region.

```hcl
variable "key_name" {
  description = "The name of the SSH key pair for accessing the instance"
  type        = string
}
```

### Shell Script to Manage Instance State and Update `.ssh/config`

Create a shell script that:
1. Starts or stops the instance using Terraform.
2. Retrieves the instance’s new IP address.
3. Updates the `.ssh/config` file with the new IP.

```bash
#!/bin/bash

ACTION=$1  # "start" or "stop"
PROFILE="default"  # Update with your AWS CLI profile if needed
INSTANCE_ID=$(terraform output -raw instance_id)

if [[ $ACTION == "start" ]]; then
    # Start the instance
    aws ec2 start-instances --instance-ids $INSTANCE_ID --profile $PROFILE
    echo "Starting instance..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --profile $PROFILE
    echo "Instance is running."
elif [[ $ACTION == "stop" ]]; then
    # Stop the instance
    aws ec2 stop-instances --instance-ids $INSTANCE_ID --profile $PROFILE
    echo "Stopping instance..."
    aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID --profile $PROFILE
    echo "Instance is stopped."
else
    echo "Invalid action. Use 'start' or 'stop'."
    exit 1
fi

# Get the current public IP after starting the instance
if [[ $ACTION == "start" ]]; then
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text --profile $PROFILE)

    # Update the .ssh/config file with the new IP
    SSH_CONFIG_ENTRY="Host my-ec2-instance
    HostName $PUBLIC_IP
    User ubuntu
    IdentityFile ~/.ssh/id_rsa"

    # Write to .ssh/config
    if grep -q "Host my-ec2-instance" ~/.ssh/config; then
        # Update existing entry
        sed -i "/Host my-ec2-instance/,+3c\\$SSH_CONFIG_ENTRY" ~/.ssh/config
    else
        # Append new entry
        echo -e "\n$SSH_CONFIG_ENTRY" >> ~/.ssh/config
    fi

    echo "Updated .ssh/config with the new IP address: $PUBLIC_IP"
fi
```

### How to Use the Script

1. **Start the Instance and Update IP**:
   ```bash
   ./manage_instance.sh start
   ```

   This will start the instance, wait until it’s running, retrieve its IP, and update the `.ssh/config` file.

2. **Stop the Instance**:
   ```bash
   ./manage_instance.sh stop
   ```

   This will stop the instance and wait until it’s in the `stopped` state.

### Explanation of `.ssh/config` Update

- The script looks for an entry with `Host my-ec2-instance` in `~/.ssh/config`. 
- If found, it replaces that entry’s `HostName` with the new IP.
- If not found, it appends a new entry at the end of `~/.ssh/config`.

### Make the Script Executable

Make sure the script is executable:

```bash
chmod +x manage_instance.sh
```

### Run Terraform to Initialize

Initialize and apply your Terraform configuration to set up the EC2 instance:

```bash
terraform init
terraform apply
```

Now, you can use `manage_instance.sh` to start and stop the instance and automatically update your `.ssh/config` with the correct IP address.