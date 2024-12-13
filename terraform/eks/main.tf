# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "ray-cluster-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required tags for EKS
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/ray-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/ray-cluster" = "shared"
  }
}

# EKS Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "ray-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    gpu = {
      name          = "gpu-node-group"
      instance_type = "g4dn.xlarge"
      min_size      = 1
      max_size      = 3
      desired_size  = 2
      capacity_type = "ON_DEMAND"

      # capacity_type = "SPOT"  # Use spot instances

      # # Handle spot termination
      # tags = {
      #   "k8s.io/cluster-autoscaler/enabled" = "true"
      #   "k8s.io/cluster-autoscaler/ray-cluster" = "owned"
      #   "aws:ec2spot:fleet-request-id" = "true"
      # }

      # # Spot instance configs
      # instance_market_options = {
      #   market_type = "spot"
      #   spot_options = {
      #     max_price = "0.50"  # Optional: set max hourly price
      #     instance_interruption_behavior = "terminate"  # or "stop"
      #   }
      # }
    }
  }
}
