#!/bin/bash

# Define variables
INSTANCE_NAME="sproutchat-devbox"
PROFILE="default"
TERRAFORM_DIR=$(dirname "$(realpath "$0")")
SSH_CONFIG_PATH="$HOME/.ssh/config"

# Define function for displaying usage information
usage() {
    echo "Usage: $0 (build|launch|start|stop|destroy) (ami|base)"
    echo "Commands:"
    echo "  build ami       - Build a new AMI."
    echo "  launch ami      - Launch instance from AMI."
    echo "  launch base     - Launch instance from base image directly."
    echo "  start ami|base  - Start the specified instance."
    echo "  stop ami|base   - Stop the specified instance."
    echo "  destroy ami|base - Destroy the specified resources."
    exit 1
}

# Check if at least two arguments are provided
if [[ $# -lt 2 ]]; then
    usage
fi

# Parse the action and target arguments
ACTION=$1
TARGET=$2

# Validate arguments
if [[ "$ACTION" == "build" && "$TARGET" != "ami" ]]; then
    echo "Error: The build action only supports the 'ami' target."
    usage
elif [[ "$ACTION" != "build" && ! "$TARGET" =~ ^(ami|base)$ ]]; then
    echo "Error: The target must be 'ami' or 'base'."
    usage
fi

# Set AWS profile for session
export AWS_PROFILE=$PROFILE

# Initialize Terraform
initialize_terraform() {
    echo "Initializing Terraform..."
    terraform -chdir="$TERRAFORM_DIR" init
}

# Apply the specified Terraform module target
apply_terraform_target() {
    local target_module="$1"
    echo "Applying Terraform target: $target_module"
    terraform -chdir="$TERRAFORM_DIR" apply -target="module.$target_module" -auto-approve
}

# Destroy the specified Terraform module target
destroy_terraform_target() {
    local target_module="$1"
    echo "Destroying Terraform target: $target_module"
    terraform -chdir="$TERRAFORM_DIR" destroy -target="module.$target_module" -auto-approve
}

# Define actions for build, launch, start, stop, and destroy
build_ami() {
    initialize_terraform
    apply_terraform_target "build_ami"
}

# Update SSH config with the latest instance's IP
update_ssh_config() {
    local instance_ip=$1
    local ssh_config_entry="Host $INSTANCE_NAME
    HostName $instance_ip
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    "

    # Create or update the SSH config entry for the instance
    if [[ -f $SSH_CONFIG_PATH ]]; then
        config_content=$(<"$SSH_CONFIG_PATH")
        if grep -q "Host $INSTANCE_NAME" <<< "$config_content"; then
            config_content=$(sed -E "/Host $INSTANCE_NAME/,/IdentityFile/ s|HostName .*|HostName $instance_ip|" <<< "$config_content")
        else
            config_content+=$'\n'"$ssh_config_entry"
        fi
    else
        config_content="$ssh_config_entry"
    fi

    echo "$config_content" > "$SSH_CONFIG_PATH"
    echo "Updated .ssh/config with the new IP address: $instance_ip"
}

launch_instance() {
    initialize_terraform
    if [[ "$TARGET" == "ami" ]]; then
        apply_terraform_target "ami_instance"
        public_ip=$(terraform -chdir="$TERRAFORM_DIR" output -raw ami_instance_public_ip)
    else
        apply_terraform_target "base_instance"
        public_ip=$(terraform -chdir="$TERRAFORM_DIR" output -raw base_instance_public_ip)
    fi
    update_ssh_config "$public_ip"
}

# Get instance ID for the specified instance type
get_instance_id() {
    instance_id=$(terraform -chdir="$TERRAFORM_DIR" output -raw "${TARGET}_instance_id" 2>/dev/null)
    if [[ -z "$instance_id" ]]; then
        echo "Error: Instance ID for $TARGET not found."
        exit 1
    fi
    echo "$instance_id"
}

start_instance() {
    instance_id=$(get_instance_id)
    echo "Starting $TARGET instance with ID: $instance_id"
    aws ec2 start-instances --instance-ids "$instance_id"
    aws ec2 wait instance-running --instance-ids "$instance_id"
    # Retrieve public IP after starting
    public_ip=$(terraform -chdir="$TERRAFORM_DIR" output -raw "${TARGET}_instance_public_ip")
    update_ssh_config "$public_ip"
}

stop_instance() {
    instance_id=$(get_instance_id)
    echo "Stopping $TARGET instance with ID: $instance_id"
    aws ec2 stop-instances --instance-ids "$instance_id"
    aws ec2 wait instance-stopped --instance-ids "$instance_id"
}

destroy_resources() {
    if [[ "$TARGET" == "ami" ]]; then
        destroy_terraform_target "ami_instance"
    else
        destroy_terraform_target "base_instance"
    fi
}

# Execute the appropriate function based on action
case "$ACTION" in
    build)
        build_ami
        ;;
    launch)
        launch_instance
        ;;
    start)
        start_instance
        ;;
    stop)
        stop_instance
        ;;
    destroy)
        destroy_resources
        ;;
    *)
        usage
        ;;
esac
