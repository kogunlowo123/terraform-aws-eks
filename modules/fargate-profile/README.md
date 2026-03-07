# EKS Fargate Profile Submodule

Reusable Terraform submodule for creating EKS Fargate profiles.

## Features

- Multiple namespace selectors with label matching
- Configurable private subnet placement
- Automatic pod execution role association

## Usage

```hcl
module "fargate_profile" {
  source = "../../modules/fargate-profile"

  cluster_name           = "my-cluster"
  name                   = "serverless"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = ["subnet-abc123", "subnet-def456"]

  selectors = [
    {
      namespace = "serverless"
      labels = {
        compute = "fargate"
      }
    },
    {
      namespace = "kube-system"
      labels = {
        k8s-app = "coredns"
      }
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the EKS cluster | string | - | yes |
| name | Name of the Fargate profile | string | - | yes |
| pod_execution_role_arn | IAM role ARN for pod execution | string | - | yes |
| subnet_ids | List of private subnet IDs | list(string) | - | yes |
| selectors | Fargate profile selectors | list(object) | - | yes |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| fargate_profile_arn | ARN of the Fargate profile |
| fargate_profile_id | ID of the Fargate profile |
| fargate_profile_status | Status of the Fargate profile |
