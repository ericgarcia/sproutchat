#!/bin/bash

# Define variables
ACTION=$1  # "build", "deploy", "start", "stop", or "destroy"
INSTANCE_NAME="sproutchat-devbox"
PROFILE="default"
TERRAFORM_DIR=$(dirname "$(realpath "$0")")
SSH_CONFIG_PATH="$HOME/.ssh/config"

# Set AWS profile
AWS_PROFILE=$PROFILE
export AWS_PROFILE

get_instance_id() {
    # Retrieve instance ID from Terraform output
    instance_id=$(terraform -chdir="$TERRAFORM_DIR" output -raw instance_id 2>/dev/null)
    if [[ $instance_id =~ ^[a-zA-Z0-9\-]+$ ]]; then
        echo "$instance_id"
    else
        echo ""
    fi
}

initialize_terraform() {
    # Initialize Terraform configuration
    echo "Initializing Terraform..."
    terraform -chdir="$TERRAFORM_DIR" init
}

apply_terraform_build() {
    # Apply Terraform configuration to build the AMI only
    echo "Building AMI with Terraform..."
    terraform -chdir="$TERRAFORM_DIR" apply -target=module.build_ami -auto-approve
}

apply_terraform_deploy() {
    # Apply Terraform configuration to deploy the instance
    echo "Deploying instance with Terraform..."
    terraform -chdir="$TERRAFORM_DIR" apply -target=module.deploy_instance -auto-approve
}

update_ssh_config() {
    local public_ip=$1
    local ssh_config_entry="Host $INSTANCE_NAME
    HostName $public_ip
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    "

    if [[ -f $SSH_CONFIG_PATH ]]; then
        config_content=$(<"$SSH_CONFIG_PATH")
        if grep -q "Host $INSTANCE_NAME" <<< "$config_content"; then
            config_content=$(sed -E "/Host $INSTANCE_NAME/,/IdentityFile/ s|HostName .*|HostName $public_ip|" <<< "$config_content")
        else
            config_content+=$'\n'"$ssh_config_entry"
        fi
    else
        config_content="$ssh_config_entry"
    fi

    echo "$config_content" > "$SSH_CONFIG_PATH"
    echo "Updated .ssh/config with the new IP address: $public_ip"
}

watch_setup() {
    # Watch the setup process by tailing the cloud-init log
    local ssh_command=("ssh" "$INSTANCE_NAME" "tail -f /var/log/cloud-init-output.log")

    while true; do
        "${ssh_command[@]}" && break || {
            echo "Waiting for the system to be available..."
            sleep 5
        }
    done
}

manage_instance() {
    local instance_id=$1
    if [[ $ACTION == "start" ]]; then
        aws ec2 start-instances --instance-ids "$instance_id"
        echo "Starting instance..."
        aws ec2 wait instance-running --instance-ids "$instance_id"
        echo "Instance is running."

        public_ip=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        update_ssh_config "$public_ip"
        watch_setup

    elif [[ $ACTION == "stop" ]]; then
        aws ec2 stop-instances --instance-ids "$instance_id"
        echo "Stopping instance..."
        aws ec2 wait instance-stopped --instance-ids "$instance_id"
        echo "Instance is stopped."

    elif [[ $ACTION == "build" ]]; then
        initialize_terraform
        apply_terraform_build

    elif [[ $ACTION == "deploy" ]]; then
        initialize_terraform
        apply_terraform_deploy

    elif [[ $ACTION == "destroy" ]]; then
        echo "Destroying all resources with Terraform..."
        terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve

    else
        echo "Invalid action. Use 'build', 'deploy', 'start', 'stop', or 'destroy'."
        exit 1
    fi
}

# Main logic
instance_id=$(get_instance_id)

if [[ -z $instance_id && $ACTION == "deploy" ]]; then
    echo "No instance found. Deploying infrastructure with Terraform..."
    apply_terraform_deploy
    instance_id=$(get_instance_id)
    if [[ -z $instance_id ]]; then
        echo "Failed to retrieve instance ID after Terraform apply."
        exit 1
    fi
else
    echo "Instance already exists with ID: $instance_id"
fi

manage_instance "$instance_id"
