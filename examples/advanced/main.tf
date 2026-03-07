################################################################################
# Advanced EKS Cluster Example
# Multiple node groups with Fargate and Spot instances
################################################################################

provider "aws" {
  region = "us-west-2"
}

module "eks" {
  source = "github.com/kogunlowo123/terraform-aws-eks"

  cluster_name    = "advanced-eks-cluster"
  cluster_version = "1.29"

  vpc_id                   = "vpc-0123456789abcdef0"
  subnet_ids               = ["subnet-private-a", "subnet-private-b", "subnet-private-c"]
  control_plane_subnet_ids = ["subnet-intra-a", "subnet-intra-b", "subnet-intra-c"]

  # Private-only cluster
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  # Encryption
  enable_cluster_encryption = true

  # Logging
  cluster_log_types          = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_days = 90

  managed_node_groups = {
    system = {
      name           = "system"
      instance_types = ["m5.xlarge", "m5a.xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      disk_size      = 100
      ami_type       = "AL2_x86_64"
      labels = {
        role = "system"
      }
      taints = [
        {
          key    = "CriticalAddonsOnly"
          effect = "NO_SCHEDULE"
        }
      ]
    }

    application = {
      name           = "application"
      instance_types = ["m5.2xlarge", "m5a.2xlarge", "m6i.2xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size       = 3
      max_size       = 20
      desired_size   = 5
      disk_size      = 100
      ami_type       = "AL2_x86_64"
      labels = {
        role = "application"
      }
    }

    spot = {
      name           = "spot-workers"
      instance_types = ["m5.xlarge", "m5a.xlarge", "m5d.xlarge", "m6i.xlarge"]
      capacity_type  = "SPOT"
      min_size       = 0
      max_size       = 50
      desired_size   = 5
      disk_size      = 50
      ami_type       = "AL2_x86_64"
      labels = {
        role     = "worker"
        capacity = "spot"
      }
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  fargate_profiles = {
    serverless = {
      name = "serverless"
      selectors = [
        {
          namespace = "serverless"
        },
        {
          namespace = "batch-jobs"
          labels = {
            compute = "fargate"
          }
        }
      ]
    }
  }

  cluster_addons = {
    vpc-cni = {
      resolve_conflicts    = "OVERWRITE"
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  # EKS Access API
  access_entries = {
    platform_admin = {
      principal_arn = "arn:aws:iam::123456789012:role/PlatformAdmin"
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    dev_team = {
      principal_arn = "arn:aws:iam::123456789012:role/DevTeam"
      type          = "STANDARD"
      policy_associations = {
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["app-*"]
          }
        }
      }
    }
  }

  tags = {
    Environment = "staging"
    Project     = "advanced-eks"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
