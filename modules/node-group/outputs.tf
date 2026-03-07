output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.this.arn
}

output "node_group_id" {
  description = "EKS cluster name and node group name separated by a colon"
  value       = aws_eks_node_group.this.id
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.this.status
}

output "node_group_resources" {
  description = "List of objects containing information about underlying resources of the node group"
  value       = aws_eks_node_group.this.resources
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.this.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.this.latest_version
}
