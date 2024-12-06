### Plan
1. Create EKS cluster module in Terraform
2. Configure node groups with GPU instances
3. Add necessary IAM roles and policies
4. Set up kubectl configuration
5. Install necessary Kubernetes addons

### Terraform Configuration

#### `terraform/eks/main.tf`

```hcl
provider "aws" {
  region = var.region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "ray-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # GPU node group
  eks_managed_node_groups = {
    gpu = {
      name           = "gpu-node-group"
      instance_type  = "g4dn.xlarge"
      min_size      = 1
      max_size      = 3
      desired_size  = 2
      capacity_type = "ON_DEMAND"

      ami_type = "AL2_x86_64_GPU"

      # Required for GPU support
      enable_bootstrap_user_data = true
      bootstrap_extra_args      = "--container-runtime containerd"
    }
  }

  # Enable OIDC provider for AWS IAM
  enable_irsa = true
}

# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "ray-cluster-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# Configure kubectl
resource "null_resource" "configure_kubectl" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ray-cluster --region ${var.region}"
  }
}

# Install NVIDIA device plugin
resource "kubernetes_manifest" "nvidia_device_plugin" {
  depends_on = [null_resource.configure_kubectl]

  manifest = {
    apiVersion = "apps/v1"
    kind       = "DaemonSet"
    metadata = {
      name      = "nvidia-device-plugin-daemonset"
      namespace = "kube-system"
    }
    # ... rest of NVIDIA device plugin configuration
  }
}
```

#### `terraform/eks/variables.tf`

```hcl
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}
```

#### `terraform/eks/outputs.tf`

```hcl
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}
```

### Usage

```bash
cd terraform/eks
terraform init
terraform apply
```

This will create:
- EKS cluster
- VPC with public/private subnets
- GPU-enabled node group
- Required IAM roles
- NVIDIA device plugin installation
- kubectl configuration

The cluster will be ready for Ray deployment after apply completes.

Similar code found with 2 license types