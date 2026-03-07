# Basic EKS Cluster Example

This example creates a simple EKS cluster with a single managed node group.

## What it creates

- EKS cluster (v1.29) with envelope encryption
- One managed node group (3x m5.large On-Demand instances)
- Core add-ons: vpc-cni, coredns, kube-proxy
- IRSA (OIDC provider)
- CloudWatch logging for all control plane components

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Connecting to the cluster

```bash
aws eks update-kubeconfig --name basic-eks-cluster --region us-east-1
kubectl get nodes
```
