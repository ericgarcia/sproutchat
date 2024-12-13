#!/bin/bash

# Define variables
INSTANCE_NAME="sproutchat-devbox"
PROFILE="default"
TERRAFORM_DIR=$(dirname "$(realpath "$0")")
SSH_CONFIG_PATH="$HOME/.ssh/config"

# Define function for displaying usage information
usage() {
    echo "Usage: $0 (build|launch|start|stop|destroy) (ami|base|eks)"
    echo "Commands:"
    echo "  build ami       - Build a new AMI."
    echo "  launch ami      - Launch instance from AMI."
    echo "  launch base     - Launch instance from base image directly."
    echo "  launch eks      - Launch EKS cluster."
    echo "  start ami|base|eks  - Start the specified instance or EKS cluster."
    echo "  stop ami|base|eks   - Stop the specified instance or EKS cluster."
    echo "  destroy ami|base|eks - Destroy the specified resources."
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
elif [[ "$ACTION" != "build" && ! "$TARGET" =~ ^(ami|base|eks)$ ]]; then
    echo "Error: The target must be 'ami', 'base', or 'eks'."
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

launch_instance() {
    initialize_terraform
    if [[ "$TARGET" == "ami" ]]; then
        apply_terraform_target "ami_instance"
    elif [[ "$TARGET" == "base" ]]; then
        apply_terraform_target "base_instance"
    elif [[ "$TARGET" == "eks" ]]; then
        apply_terraform_target "eks"
    fi
}

start_instance() {
    initialize_terraform
    if [[ "$TARGET" == "ami" || "$TARGET" == "base" ]]; then
        apply_terraform_target "${TARGET}_instance"
    elif [[ "$TARGET" == "eks" ]]; then
        apply_terraform_target "eks"
    fi
}

stop_instance() {
    initialize_terraform
    if [[ "$TARGET" == "ami" || "$TARGET" == "base" ]]; then
        destroy_terraform_target "${TARGET}_instance"
    elif [[ "$TARGET" == "eks" ]]; then
        destroy_terraform_target "eks"
    fi
}

destroy_instance() {
    initialize_terraform
    if [[ "$TARGET" == "ami" || "$TARGET" == "base" ]]; then
        destroy_terraform_target "${TARGET}_instance"
    elif [[ "$TARGET" == "eks" ]]; then
        destroy_terraform_target "eks"
    fi
}

# Execute the specified action
case $ACTION in
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
        destroy_instance
        ;;
    *)
        usage
        ;;
esac