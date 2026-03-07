# Advanced EKS Cluster Example

Multi-node-group EKS cluster with Fargate profiles, Spot instances, and EKS access API.

## What it creates

- Private EKS cluster (v1.29) with envelope encryption
- Three managed node groups:
  - **system**: Dedicated On-Demand nodes for critical add-ons (tainted)
  - **application**: On-Demand nodes for workloads
  - **spot**: Spot instances for cost-optimized batch processing (tainted)
- Fargate profile for serverless workloads
- All 5 managed add-ons including EBS CSI and Pod Identity
- EKS access entries for platform admin and dev team roles
- VPC CNI with prefix delegation for higher pod density

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Architecture Notes

- Control plane ENIs are placed in isolated (intra) subnets
- Worker nodes run in private subnets only
- No public endpoint access -- use a bastion, VPN, or SSM Session Manager
- Spot nodes have taints requiring tolerations for workload placement
