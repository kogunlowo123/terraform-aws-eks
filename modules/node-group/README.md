# EKS Node Group Submodule

Reusable Terraform submodule for creating EKS managed node groups with a custom launch template.

## Features

- Custom launch template with IMDSv2 enforcement
- Encrypted EBS volumes (gp3)
- Detailed monitoring enabled
- Support for Spot and On-Demand capacity types
- Kubernetes labels and taints
- Rolling update configuration

## Usage

```hcl
module "node_group" {
  source = "../../modules/node-group"

  cluster_name   = "my-cluster"
  name           = "general"
  node_role_arn  = aws_iam_role.node.arn
  subnet_ids     = ["subnet-abc123", "subnet-def456"]
  instance_types = ["m5.large", "m5a.large"]
  capacity_type  = "ON_DEMAND"
  min_size       = 2
  max_size       = 10
  desired_size   = 3
  disk_size      = 100

  labels = {
    workload = "general"
  }

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the EKS cluster | string | - | yes |
| name | Name of the node group | string | - | yes |
| node_role_arn | IAM role ARN for the node group | string | - | yes |
| subnet_ids | List of subnet IDs | list(string) | - | yes |
| instance_types | EC2 instance types | list(string) | ["m5.large"] | no |
| capacity_type | ON_DEMAND or SPOT | string | "ON_DEMAND" | no |
| ami_type | AMI type for the node group | string | "AL2_x86_64" | no |
| min_size | Minimum number of nodes | number | 1 | no |
| max_size | Maximum number of nodes | number | 3 | no |
| desired_size | Desired number of nodes | number | 2 | no |
| disk_size | Disk size in GiB | number | 50 | no |
| labels | Kubernetes labels | map(string) | {} | no |
| taints | Kubernetes taints | list(object) | [] | no |
| kms_key_arn | KMS key ARN for EBS encryption | string | null | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| node_group_arn | ARN of the EKS node group |
| node_group_id | ID of the EKS node group |
| node_group_status | Status of the EKS node group |
| launch_template_id | ID of the launch template |
