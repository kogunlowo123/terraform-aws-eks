# Complete Enterprise EKS Cluster Example

Full-featured enterprise EKS deployment with all module capabilities enabled.

## What it creates

### EKS Cluster
- Private-only EKS cluster (v1.29) with custom KMS encryption key
- Full control plane logging with 365-day retention
- IRSA via OIDC provider

### Node Groups (5 groups)
- **system**: Dedicated On-Demand nodes for critical add-ons (AL2023, tainted)
- **application**: General-purpose On-Demand nodes for workloads (AL2023)
- **gpu**: GPU nodes for ML inference (g5.2xlarge, AL2 GPU AMI, tainted)
- **spot-batch**: Spot instances for batch processing (diversified, tainted)
- **arm-general**: Graviton-based nodes for cost optimization (AL2023 ARM)

### Fargate Profiles (3 profiles)
- **kube-system**: CoreDNS on Fargate
- **serverless**: General serverless workloads
- **monitoring**: Fargate-based monitoring components

### Add-ons
- vpc-cni with prefix delegation
- coredns configured for Fargate compute
- kube-proxy
- aws-ebs-csi-driver
- eks-pod-identity-agent

### Access Control
- Platform Engineering: cluster admin
- SRE Team: admin access
- Dev Team: edit access (scoped to app namespaces)
- Auditor: read-only cluster-wide
- CI/CD Pipeline: edit access (deployment namespaces)

### IRSA Roles
- External Secrets Operator (Secrets Manager + SSM)
- AWS Load Balancer Controller
- Cluster Autoscaler

## Usage

```bash
terraform init
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

## Connecting to the cluster

Since this is a private-only cluster, connect via VPN, bastion host, or SSM:

```bash
aws eks update-kubeconfig --name enterprise-eks --region eu-west-1
kubectl get nodes
```

## Cost Estimation

Approximate monthly cost (eu-west-1):
- EKS control plane: ~$73
- System nodes (3x m6i.xlarge): ~$420
- Application nodes (6x m6i.2xlarge): ~$1,680
- ARM nodes (2x m6g.xlarge): ~$220
- GPU/Spot nodes: variable (scaled to zero by default)
- CloudWatch Logs: variable
- KMS: ~$1
- **Estimated baseline: ~$2,400/month**
