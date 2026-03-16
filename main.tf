################################################################################
# EKS Cluster
################################################################################

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = length(var.control_plane_subnet_ids) > 0 ? var.control_plane_subnet_ids : var.subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  dynamic "encryption_config" {
    for_each = var.enable_cluster_encryption ? [1] : []
    content {
      provider {
        key_arn = var.enable_cluster_encryption ? (var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn) : null
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.cluster_log_types

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_controller,
    aws_cloudwatch_log_group.eks,
  ]
}

################################################################################
# CloudWatch Log Group for EKS Control Plane Logs
################################################################################

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days
  kms_key_id        = var.enable_cluster_encryption ? (var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn) : null

  tags = var.tags
}

################################################################################
# Launch Templates for Node Groups
################################################################################

resource "aws_launch_template" "node_group" {
  for_each = var.managed_node_groups

  name_prefix = "${var.cluster_name}-${each.value.name}-"
  description = "Launch template for EKS managed node group ${each.value.name}"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = each.value.disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.enable_cluster_encryption ? (var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn) : null
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, each.value.tags, {
      Name = "${var.cluster_name}-${each.value.name}"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, each.value.tags, {
      Name = "${var.cluster_name}-${each.value.name}"
    })
  }

  tags = merge(var.tags, each.value.tags)

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# EKS Managed Node Groups
################################################################################

resource "aws_eks_node_group" "this" {
  for_each = var.managed_node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.value.name
  node_role_arn   = aws_iam_role.node_group[each.key].arn
  subnet_ids      = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : var.subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  ami_type       = each.value.ami_type

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  launch_template {
    id      = aws_launch_template.node_group[each.key].id
    version = aws_launch_template.node_group[each.key].latest_version
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker,
    aws_iam_role_policy_attachment.node_group_cni,
    aws_iam_role_policy_attachment.node_group_ecr,
    aws_iam_role_policy_attachment.node_group_ssm,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

################################################################################
# EKS Fargate Profiles
################################################################################

resource "aws_eks_fargate_profile" "this" {
  for_each = var.fargate_profiles

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = each.value.name
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : var.subnet_ids

  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }

  tags = var.tags
}

################################################################################
# EKS Add-ons
################################################################################

resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = each.value.resolve_conflicts
  resolve_conflicts_on_update = each.value.resolve_conflicts
  configuration_values        = each.value.configuration_values

  tags = var.tags

  depends_on = [
    aws_eks_node_group.this,
    aws_eks_fargate_profile.this,
  ]
}

################################################################################
# EKS Access Entries
################################################################################

resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value.principal_arn
  kubernetes_groups = each.value.kubernetes_groups
  type              = each.value.type

  tags = var.tags
}

resource "aws_eks_access_policy_association" "this" {
  for_each = {
    for assoc in flatten([
      for entry_key, entry in var.access_entries : [
        for policy_key, policy in entry.policy_associations : {
          entry_key     = entry_key
          policy_key    = policy_key
          principal_arn = entry.principal_arn
          policy_arn    = policy.policy_arn
          access_scope  = policy.access_scope
        }
      ]
    ]) : "${assoc.entry_key}-${assoc.policy_key}" => assoc
  }

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope.type
    namespaces = each.value.access_scope.type == "namespace" ? each.value.access_scope.namespaces : null
  }

  depends_on = [aws_eks_access_entry.this]
}
