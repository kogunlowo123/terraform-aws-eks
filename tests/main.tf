terraform {
  required_version = ">= 1.7.0"
}

module "test" {
  source = "../"

  cluster_name    = "test-eks-cluster"
  cluster_version = "1.29"
  vpc_id          = "vpc-0123456789abcdef0"
  subnet_ids      = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  managed_node_groups = {
    default = {
      name           = "default"
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      disk_size      = 50
      ami_type       = "AL2_x86_64"
    }
  }

  tags = {
    Environment = "test"
    Module      = "terraform-aws-eks"
  }
}
