################################################################################
# Complete Enterprise EKS Cluster Example
# All features enabled: multi-node-group, Fargate, IRSA, add-ons, access API
################################################################################

provider "aws" {
  region = "eu-west-1"
}

locals {
  cluster_name = "enterprise-eks"
  environment  = "production"

  tags = {
    Environment  = local.environment
    Project      = "enterprise-platform"
    ManagedBy    = "terraform"
    CostCenter   = "platform-engineering"
    Compliance   = "soc2"
    DataClass    = "confidential"
  }
}

################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source = "github.com/kogunlowo123/terraform-aws-eks"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  vpc_id                   = "vpc-0123456789abcdef0"
  subnet_ids               = ["subnet-private-a", "subnet-private-b", "subnet-private-c"]
  control_plane_subnet_ids = ["subnet-intra-a", "subnet-intra-b", "subnet-intra-c"]

  # Private-only endpoint (production hardened)
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  # Envelope encryption with custom KMS key
  enable_cluster_encryption = true
  kms_key_arn               = "arn:aws:kms:eu-west-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Full control plane logging
  cluster_log_types          = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_days = 365

  # IRSA enabled
  enable_irsa = true

  ##############################################################################
  # Managed Node Groups
  ##############################################################################

  managed_node_groups = {
    # Critical system components
    system = {
      name           = "system"
      instance_types = ["m6i.xlarge", "m5.xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size       = 3
      max_size       = 6
      desired_size   = 3
      disk_size      = 100
      ami_type       = "AL2023_x86_64_STANDARD"
      labels = {
        "node.kubernetes.io/purpose" = "system"
      }
      taints = [
        {
          key    = "CriticalAddonsOnly"
          effect = "NO_SCHEDULE"
        }
      ]
      tags = {
        NodeGroupRole = "system"
      }
    }

    # General-purpose application workloads
    application = {
      name           = "application"
      instance_types = ["m6i.2xlarge", "m5.2xlarge", "m6a.2xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size       = 3
      max_size       = 50
      desired_size   = 6
      disk_size      = 200
      ami_type       = "AL2023_x86_64_STANDARD"
      labels = {
        "node.kubernetes.io/purpose" = "application"
      }
      tags = {
        NodeGroupRole = "application"
      }
    }

    # GPU workloads (ML inference)
    gpu = {
      name           = "gpu"
      instance_types = ["g5.2xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size       = 0
      max_size       = 10
      desired_size   = 0
      disk_size      = 200
      ami_type       = "AL2_x86_64_GPU"
      labels = {
        "node.kubernetes.io/purpose" = "gpu"
        "nvidia.com/gpu"             = "true"
      }
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
      tags = {
        NodeGroupRole = "gpu"
      }
    }

    # Cost-optimized Spot workers for batch processing
    spot_batch = {
      name = "spot-batch"
      instance_types = [
        "m6i.2xlarge", "m5.2xlarge", "m6a.2xlarge",
        "m5a.2xlarge", "m5d.2xlarge", "m5n.2xlarge"
      ]
      capacity_type = "SPOT"
      min_size      = 0
      max_size      = 100
      desired_size  = 0
      disk_size     = 100
      ami_type      = "AL2023_x86_64_STANDARD"
      labels = {
        "node.kubernetes.io/purpose" = "batch"
        "node.kubernetes.io/lifecycle" = "spot"
      }
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
      tags = {
        NodeGroupRole = "spot-batch"
      }
    }

    # ARM-based nodes for cost optimization
    arm_general = {
      name           = "arm-general"
      instance_types = ["m6g.xlarge", "m7g.xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size       = 0
      max_size       = 20
      desired_size   = 2
      disk_size      = 100
      ami_type       = "AL2023_ARM_64_STANDARD"
      labels = {
        "node.kubernetes.io/purpose" = "arm-workloads"
        "kubernetes.io/arch"         = "arm64"
      }
      tags = {
        NodeGroupRole = "arm-general"
      }
    }
  }

  ##############################################################################
  # Fargate Profiles
  ##############################################################################

  fargate_profiles = {
    kube_system = {
      name = "kube-system"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "coredns"
          }
        }
      ]
    }

    serverless = {
      name = "serverless"
      selectors = [
        {
          namespace = "serverless"
        },
        {
          namespace = "lambda-functions"
        }
      ]
    }

    monitoring = {
      name = "monitoring-fargate"
      selectors = [
        {
          namespace = "monitoring"
          labels = {
            compute = "fargate"
          }
        }
      ]
    }
  }

  ##############################################################################
  # Managed Add-ons
  ##############################################################################

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
      resolve_conflicts    = "OVERWRITE"
      configuration_values = jsonencode({
        computeType = "Fargate"
      })
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

  ##############################################################################
  # EKS Access API
  ##############################################################################

  access_entries = {
    # Platform engineering team - full admin
    platform_admin = {
      principal_arn = "arn:aws:iam::123456789012:role/PlatformEngineering"
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

    # SRE team - admin for operations
    sre_team = {
      principal_arn = "arn:aws:iam::123456789012:role/SRETeam"
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # Development team - edit access to app namespaces
    dev_team = {
      principal_arn = "arn:aws:iam::123456789012:role/DevTeam"
      type          = "STANDARD"
      policy_associations = {
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["app-production", "app-staging"]
          }
        }
      }
    }

    # Read-only access for auditors
    auditor = {
      principal_arn = "arn:aws:iam::123456789012:role/Auditor"
      type          = "STANDARD"
      policy_associations = {
        view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # CI/CD pipeline role
    cicd = {
      principal_arn = "arn:aws:iam::123456789012:role/CICDPipeline"
      type          = "STANDARD"
      policy_associations = {
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["app-production", "app-staging", "argocd"]
          }
        }
      }
    }
  }

  tags = local.tags
}

################################################################################
# IRSA Examples
################################################################################

# External Secrets Operator
module "irsa_external_secrets" {
  source = "../../modules/irsa"

  role_name         = "${local.cluster_name}-external-secrets"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_issuer

  service_accounts = [
    {
      namespace = "external-secrets"
      name      = "external-secrets"
    }
  ]

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "ssm:GetParameter",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

# AWS Load Balancer Controller
module "irsa_alb_controller" {
  source = "../../modules/irsa"

  role_name         = "${local.cluster_name}-aws-lb-controller"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_issuer

  service_accounts = [
    {
      namespace = "kube-system"
      name      = "aws-load-balancer-controller"
    }
  ]

  policy_arns = [
    "arn:aws:iam::123456789012:policy/AWSLoadBalancerControllerPolicy"
  ]

  tags = local.tags
}

# Cluster Autoscaler
module "irsa_cluster_autoscaler" {
  source = "../../modules/irsa"

  role_name         = "${local.cluster_name}-cluster-autoscaler"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_issuer

  service_accounts = [
    {
      namespace = "kube-system"
      name      = "cluster-autoscaler"
    }
  ]

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"             = "true"
            "aws:ResourceTag/k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
          }
        }
      }
    ]
  })

  tags = local.tags
}

################################################################################
# Outputs
################################################################################

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "node_group_arns" {
  description = "ARNs of all managed node groups"
  value       = module.eks.node_group_arns
}

output "fargate_profile_arns" {
  description = "ARNs of all Fargate profiles"
  value       = module.eks.fargate_profile_arns
}

output "external_secrets_role_arn" {
  description = "IRSA role ARN for External Secrets"
  value       = module.irsa_external_secrets.role_arn
}

output "alb_controller_role_arn" {
  description = "IRSA role ARN for AWS Load Balancer Controller"
  value       = module.irsa_alb_controller.role_arn
}
