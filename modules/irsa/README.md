# IRSA (IAM Roles for Service Accounts) Submodule

Helper module for creating IAM roles that can be assumed by Kubernetes service accounts via OIDC federation.

## Features

- OIDC-based trust policy for secure pod-level IAM
- Support for multiple service accounts per role
- Managed and inline policy attachment
- Permissions boundary support
- StringEquals or StringLike condition for wildcard matching

## Usage

```hcl
module "irsa_s3_reader" {
  source = "../../modules/irsa"

  role_name         = "my-cluster-s3-reader"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_issuer

  service_accounts = [
    {
      namespace = "default"
      name      = "s3-reader"
    }
  ]

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| role_name | Name of the IAM role | string | - | yes |
| oidc_provider_arn | ARN of the EKS OIDC provider | string | - | yes |
| oidc_provider_url | URL of the EKS OIDC provider | string | - | yes |
| service_accounts | Kubernetes service accounts to bind | list(object) | - | yes |
| assume_role_condition_test | StringEquals or StringLike | string | "StringEquals" | no |
| policy_arns | IAM policy ARNs to attach | list(string) | [] | no |
| inline_policy | JSON inline policy | string | null | no |
| permissions_boundary_arn | Permissions boundary ARN | string | null | no |
| role_path | IAM role path | string | "/" | no |
| max_session_duration | Max session duration (seconds) | number | 3600 | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |
| role_unique_id | Unique ID of the IAM role |
