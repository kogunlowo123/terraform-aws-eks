output "fargate_profile_arn" {
  description = "ARN of the EKS Fargate profile"
  value       = aws_eks_fargate_profile.this.arn
}

output "fargate_profile_id" {
  description = "EKS cluster name and Fargate profile name separated by a colon"
  value       = aws_eks_fargate_profile.this.id
}

output "fargate_profile_status" {
  description = "Status of the EKS Fargate profile"
  value       = aws_eks_fargate_profile.this.status
}
