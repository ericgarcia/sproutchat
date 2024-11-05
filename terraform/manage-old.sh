#!/bin/bash

# Define variables
INSTANCE_NAME="sproutchat-devbox"
PROFILE="default"
SCRIPT_DIR=$(dirname "$(realpath "$0")")
TERRAFORM_SHARED_DIR="$SCRIPT_DIR/terraform/shared"
TERRAFORM_AMI_DIR="$SCRIPT_DIR/terraform/ami"
TERRAFORM_MAIN_DIR="$SCRIPT_DIR/terraform/main"
SSH_CONFIG_PATH="$HOME/.ssh/config"
LAST_INSTANCE_FILE="$SCRIPT_DIR/.last_instance_module"
ACTION="$1"  # Use the first positional argument as the action
INSTANCE_TYPE="$2"  # Use the second positional argument as the instance type (ami or base)

# Set AWS profile
AWS_PROFILE=$PROFILE
export AWS_PROFILE

# Display usage information
usage() {
    echo "Usage: $0 <build-ami|launch-ami|launch-base|start|stop|destroy> [ami|base] [--help]"
    echo
    echo "Actions:"
    echo "  build-ami      Build the AMI using the build_ami module"
    echo "  launch-ami     Launch the instance using the ami_instance module"
    echo "  launch-base    Launch a direct instance without AMI using the base_instance module"
    echo "  start          Start the last created EC2 instance (ami or base)"
    echo "  stop           Stop the last created EC2 instance (ami or base)"
    echo "  destroy        Destroy all Terraform-managed resources"
    echo
    echo "Options:"
    echo "  --help         Display this help message"
    exit 1
}

# Parse arguments
if [[ "$ACTION" == "--help" || -z "$ACTION" ]]; then
    usage
fi

initialize_shared() {
    echo "Initializing shared resources..."
    cd $TERRAFORM_SHARED_DIR
    terraform init
    terraform apply -auto-approve
    IAM_INSTANCE_PROFILE=$(terraform output -raw iam_instance_profile)
    SECURITY_GROUP_ID=$(terraform output -raw security_group_id)
    cd -
}

build_ami() {
    echo "Building AMI..."
    cd $TERRAFORM_AMI_DIR
    terraform init
    terraform apply -auto-approve -var "iam_instance_profile=$IAM_INSTANCE_PROFILE" -var "security_group_id=$SECURITY_GROUP_ID"
    AMI_ID=$(terraform output -raw ami_id)
    echo "AMI built with ID: $AMI_ID"
    cd -
}

launch_ami() {
    echo "Launching instance using AMI..."
    cd $TERRAFORM_MAIN_DIR
    terraform init
    terraform apply -auto-approve -var "base_ami_id=$AMI_ID"
    echo "ami" > $LAST_INSTANCE_FILE
    cd -
}

launch_base() {
    echo "Launching base instance..."
    cd $TERRAFORM_MAIN_DIR
    terraform init
    terraform apply -auto-approve
    echo "base" > $LAST_INSTANCE_FILE
    cd -
}

get_instance_info() {
    local instance_type=$1
    instance_id=$(terraform -chdir="$TERRAFORM_MAIN_DIR" output -raw "${instance_type}_instance_id")
    public_ip=$(terraform -chdir="$TERRAFORM_MAIN_DIR" output -raw "${instance_type}_instance_public_ip")
    echo "Instance ID ($instance_type): $instance_id"
    echo "Public IP ($instance_type): $public_ip"
}

start_instance() {
    local instance_type=$1
    get_instance_info $instance_type
    aws ec2 start-instances --instance-ids "$instance_id"
    aws ec2 wait instance-running --instance-ids "$instance_id"
    echo "Instance ($instance_type) started."
}

stop_instance() {
    local instance_type=$1
    get_instance_info $instance_type
    aws ec2 stop-instances --instance-ids "$instance_id"
    aws ec2 wait instance-stopped --instance-ids "$instance_id"
    echo "Instance ($instance_type) stopped."
}

destroy_resources() {
    echo "Destroying all Terraform-managed resources..."
    cd $TERRAFORM_MAIN_DIR
    terraform destroy -auto-approve
    cd $TERRAFORM_AMI_DIR
    terraform destroy -auto-approve
    cd $TERRAFORM_SHARED_DIR
    terraform destroy -auto-approve
    cd -
}

case $ACTION in
    build-ami)
        initialize_shared
        build_ami
        ;;
    launch-ami)
        initialize_shared
        build_ami
        launch_ami
        ;;
    launch-base)
        initialize_shared
        launch_base
        ;;
    start)
        if [[ -z "$INSTANCE_TYPE" ]]; then
            echo "Error: Instance type (ami or base) is required for start action."
            usage
        fi
        start_instance $INSTANCE_TYPE
        ;;
    stop)
        if [[ -z "$INSTANCE_TYPE" ]]; then
            echo "Error: Instance type (ami or base) is required for stop action."
            usage
        fi
        stop_instance $INSTANCE_TYPE
        ;;
    destroy)
        destroy_resources
        ;;
    *)
        echo "Invalid action. Use 'build-ami', 'launch-ami', 'launch-base', 'start', 'stop', or 'destroy'."
        usage
        ;;
esac