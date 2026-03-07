################################################################################
# Cluster Outputs
################################################################################

output "cluster_id" {
  description = "The ID of the EKS cluster (same as cluster name)"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster CA"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "The platform version of the EKS cluster"
  value       = aws_eks_cluster.this.platform_version
}

################################################################################
# Security Group Outputs
################################################################################

output "cluster_security_group_id" {
  description = "The ID of the cluster security group"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "The ID of the node security group"
  value       = aws_security_group.node.id
}

output "cluster_primary_security_group_id" {
  description = "The ID of the EKS-managed cluster security group"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

################################################################################
# OIDC / IRSA Outputs
################################################################################

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for IRSA"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.eks[0].arn : null
}

output "oidc_provider_url" {
  description = "The URL of the OIDC provider (without https://)"
  value       = var.enable_irsa ? replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "") : null
}

output "oidc_issuer" {
  description = "The full OIDC issuer URL of the EKS cluster"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

################################################################################
# Node Group Outputs
################################################################################

output "node_group_arns" {
  description = "Map of node group names to their ARNs"
  value = {
    for k, v in aws_eks_node_group.this : k => v.arn
  }
}

output "node_group_status" {
  description = "Map of node group names to their status"
  value = {
    for k, v in aws_eks_node_group.this : k => v.status
  }
}

output "node_group_role_arns" {
  description = "Map of node group names to their IAM role ARNs"
  value = {
    for k, v in aws_iam_role.node_group : k => v.arn
  }
}

################################################################################
# Fargate Profile Outputs
################################################################################

output "fargate_profile_arns" {
  description = "Map of Fargate profile names to their ARNs"
  value = {
    for k, v in aws_eks_fargate_profile.this : k => v.arn
  }
}

output "fargate_role_arn" {
  description = "The ARN of the Fargate pod execution IAM role"
  value       = aws_iam_role.fargate.arn
}

################################################################################
# IAM Outputs
################################################################################

output "cluster_iam_role_arn" {
  description = "The ARN of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "The name of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.name
}

################################################################################
# KMS Outputs
################################################################################

output "kms_key_arn" {
  description = "The ARN of the KMS key used for cluster encryption"
  value       = var.enable_cluster_encryption ? local.kms_key_arn : null
}
