locals {
  cluster_name = var.cluster_name

  control_plane_subnet_ids = length(var.control_plane_subnet_ids) > 0 ? var.control_plane_subnet_ids : var.subnet_ids

  # Use provided KMS key or the one created by this module
  kms_key_arn = var.enable_cluster_encryption ? (
    var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn
  ) : null

  common_tags = merge(var.tags, {
    "terraform.io/module"    = "terraform-aws-eks"
    "eks.amazonaws.com/name" = local.cluster_name
  })

  # Flatten access policy associations for for_each
  access_policy_associations = flatten([
    for entry_key, entry in var.access_entries : [
      for policy_key, policy in entry.policy_associations : {
        entry_key     = entry_key
        policy_key    = policy_key
        principal_arn = entry.principal_arn
        policy_arn    = policy.policy_arn
        access_scope  = policy.access_scope
      }
    ]
  ])
}
