# EKS Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access = var.cluster_endpoint_public_access

  eks_managed_node_groups = {
    gpu = {
      name          = "gpu-node-group"
      instance_type = "g4dn.xlarge"
      min_size      = 1
      max_size      = 2
      desired_size  = 1
      capacity_type = "ON_DEMAND"
    }
  }
}

# Update aws-auth ConfigMap
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = jsonencode([
      {
        rolearn  = var.ec2_instance_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
  }
}
