# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-01

### Added

- EKS cluster resource with configurable Kubernetes version and access configuration
- Managed node groups with custom launch templates enforcing IMDSv2
- Fargate profiles with namespace and label selectors
- EKS managed add-ons support (vpc-cni, coredns, kube-proxy, ebs-csi, pod-identity-agent)
- IAM Roles for Service Accounts (IRSA) via OIDC provider
- EKS Access API with access entries and policy associations
- KMS envelope encryption for Kubernetes secrets with auto-created or existing key
- CloudWatch control plane logging with configurable retention
- Cluster and node security groups with least-privilege rules
- Encrypted gp3 EBS volumes for all node groups
- Reusable submodules: node-group, fargate-profile, irsa
- Basic, advanced, and complete usage examples
- Comprehensive documentation with architecture diagram
