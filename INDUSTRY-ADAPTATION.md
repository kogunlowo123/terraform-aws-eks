# Industry Adaptation Guide

## Overview
The `terraform-aws-eks` module provisions a production-grade Amazon EKS cluster with managed node groups, Fargate profiles, cluster add-ons, encryption, logging, and IRSA. Its configurable security posture, network isolation, and access controls make it adaptable to virtually any regulated or unregulated industry.

## Healthcare
### Compliance Requirements
- HIPAA, HITRUST, HL7 FHIR
### Configuration Changes
- Set `cluster_endpoint_public_access = false` and `cluster_endpoint_private_access = true` to ensure the API server is not internet-accessible.
- Set `enable_cluster_encryption = true` with a dedicated `kms_key_arn` (customer-managed key) to satisfy HIPAA encryption-at-rest requirements for Kubernetes secrets.
- Enable all log types via `cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]` and set `cluster_log_retention_days = 365` or higher for audit trail retention.
- Use `managed_node_groups` with `capacity_type = "ON_DEMAND"` for predictable performance of clinical workloads.
- Deploy workloads to dedicated namespaces with IRSA (`enable_irsa = true`) so each microservice has least-privilege IAM access.
- Restrict access with `access_entries` scoped to specific namespaces via `access_scope.type = "namespace"`.
### Example Use Case
A hospital system runs its FHIR-compliant patient data platform on EKS with encrypted secrets, private endpoints, and namespace-level access controls separating clinical, analytics, and administrative workloads.

## Finance
### Compliance Requirements
- SOX, PCI-DSS, SOC 2
### Configuration Changes
- Set `enable_cluster_encryption = true` with a customer-managed `kms_key_arn` for envelope encryption of secrets (PCI-DSS Requirement 3).
- Restrict `cluster_endpoint_public_access_cidrs` to known corporate CIDR blocks if public access must remain enabled; prefer `cluster_endpoint_public_access = false`.
- Set `cluster_log_retention_days = 365` to meet SOX audit retention requirements.
- Use `managed_node_groups` with `ami_type = "BOTTLEROCKET_x86_64"` for a minimal, hardened OS with reduced attack surface.
- Use `taints` and `labels` on node groups to isolate PCI cardholder data workloads onto dedicated nodes.
- Enable IRSA (`enable_irsa = true`) and use `access_entries` with `policy_associations` to enforce least-privilege access.
### Example Use Case
A fintech company deploys its payment processing microservices on EKS with Bottlerocket nodes, KMS encryption, and tainted node groups that isolate PCI-scoped workloads from non-PCI services.

## Government
### Compliance Requirements
- FedRAMP, CMMC, NIST 800-53
### Configuration Changes
- Set `cluster_endpoint_public_access = false` to meet NIST AC-17 (Remote Access) controls.
- Enable all `cluster_log_types` and set `cluster_log_retention_days = 365` for continuous monitoring (NIST AU-2, AU-11).
- Use `enable_cluster_encryption = true` with a FIPS-validated `kms_key_arn` (NIST SC-28).
- Deploy to `control_plane_subnet_ids` in GovCloud-region subnets.
- Use `access_entries` with `type = "STANDARD"` and restrict `kubernetes_groups` and `policy_associations` for role-based access (NIST AC-2, AC-3).
- Use `managed_node_groups` with `ami_type = "AL2023_x86_64_STANDARD"` for the latest hardened Amazon Linux.
### Example Use Case
A federal agency runs its IL-4 workloads on EKS in AWS GovCloud with private-only endpoints, FIPS KMS encryption, and RBAC access entries mapped to PIV-authenticated IAM roles.

## Retail / E-Commerce
### Compliance Requirements
- PCI-DSS, CCPA/GDPR
### Configuration Changes
- Enable `cluster_addons` for `vpc-cni`, `coredns`, and `kube-proxy` to support high-throughput microservice communication.
- Use `managed_node_groups` with `capacity_type = "SPOT"` for non-critical batch jobs (inventory updates, recommendations) and `"ON_DEMAND"` for checkout/payment services.
- Configure autoscaling via `min_size`, `max_size`, and `desired_size` to handle Black Friday traffic spikes.
- Use `fargate_profiles` for ephemeral, bursty workloads like image rendering or order notification processors.
- Set `enable_cluster_encryption = true` for PCI-DSS compliance on cardholder data at rest.
### Example Use Case
An e-commerce platform uses EKS with mixed ON_DEMAND and SPOT node groups, Fargate profiles for notification services, and encrypted secrets for payment gateway credentials, scaling from 3 to 50 nodes during peak sales events.

## Education
### Compliance Requirements
- FERPA, COPPA
### Configuration Changes
- Set `cluster_endpoint_public_access = false` to protect student data environments.
- Enable `enable_cluster_encryption = true` to encrypt student PII stored in Kubernetes secrets.
- Use `access_entries` with namespace-scoped `policy_associations` to separate student-facing apps from administrative systems.
- Set `cluster_log_retention_days = 365` to maintain audit records for FERPA compliance.
- Use `labels` on `managed_node_groups` to tag workloads by data classification (e.g., `data-classification: ferpa-protected`).
### Example Use Case
A university runs its student information system and learning management platform on EKS with namespace isolation between student services, faculty tools, and research computing clusters.

## SaaS / Multi-Tenant
### Compliance Requirements
- SOC 2, ISO 27001
### Configuration Changes
- Use `managed_node_groups` with distinct `labels` and `taints` per tenant tier (e.g., `tenant-tier: premium` with `NoSchedule` taints) to enforce workload isolation.
- Configure multiple `fargate_profiles` with `selectors` that map each tenant's namespace for serverless isolation.
- Enable IRSA (`enable_irsa = true`) so each tenant's service accounts map to tenant-specific IAM roles.
- Use `access_entries` with namespace-scoped `access_scope` to restrict tenant operators to their own namespaces.
- Enable all `cluster_log_types` for SOC 2 audit evidence and set `cluster_log_retention_days = 365`.
- Set `cluster_endpoint_public_access = false` and use `control_plane_subnet_ids` for dedicated control plane networking.
### Example Use Case
A B2B SaaS provider hosts 200+ tenants on a shared EKS cluster, using namespace-per-tenant isolation, Fargate profiles for burst workloads, and IRSA to ensure each tenant's pods can only access their own S3 buckets and DynamoDB tables.

## Cross-Industry Best Practices
- Use environment-based configuration by parameterizing `cluster_name`, `tags`, and network settings per environment (dev/staging/prod).
- Always enable encryption at rest (`enable_cluster_encryption = true`) and in transit (private endpoints, TLS).
- Enable comprehensive audit logging with all five `cluster_log_types` and retain logs for at least 90 days.
- Enforce least-privilege access controls via `access_entries` with namespace-scoped policies and IRSA for pod-level IAM.
- Implement network segmentation by deploying worker nodes in private subnets (`subnet_ids`) and control plane in isolated subnets (`control_plane_subnet_ids`).
- Configure backup and disaster recovery by leveraging multi-AZ `subnet_ids` (minimum 2 required) and maintaining IaC state in versioned remote backends.
