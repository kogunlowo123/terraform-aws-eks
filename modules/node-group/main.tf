################################################################################
# Reusable EKS Managed Node Group
################################################################################

resource "aws_launch_template" "this" {
  name_prefix = "${var.cluster_name}-${var.name}-"
  description = "Launch template for EKS managed node group ${var.name}"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
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
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-${var.name}"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-${var.name}"
    })
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  ami_type       = var.ami_type

  scaling_config {
    min_size     = var.min_size
    max_size     = var.max_size
    desired_size = var.desired_size
  }

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  labels = var.labels

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
