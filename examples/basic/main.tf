################################################################################
# Basic EKS Cluster Example
# Single managed node group with sensible defaults
################################################################################

provider "aws" {
  region = "us-east-1"
}

module "eks" {
  source = "github.com/kogunlowo123/terraform-aws-eks"

  cluster_name    = "basic-eks-cluster"
  cluster_version = "1.29"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1", "subnet-0123456789abcdef2"]

  # Allow public access for development
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["203.0.113.0/24"]

  managed_node_groups = {
    general = {
      name           = "general"
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 5
      desired_size   = 3
      disk_size      = 50
      ami_type       = "AL2_x86_64"
    }
  }

  cluster_addons = {
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  tags = {
    Environment = "development"
    Project     = "basic-eks"
    ManagedBy   = "terraform"
  }
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_id
}
