################################################################################
# EKS Cluster IAM Role
################################################################################

data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    sid     = "EKSClusterAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"
  path = "/"

  assume_role_policy    = data.aws_iam_policy_document.cluster_assume_role.json
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_controller" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

################################################################################
# KMS Policy for Cluster Role (envelope encryption)
################################################################################

data "aws_iam_policy_document" "cluster_kms" {
  count = var.enable_cluster_encryption ? 1 : 0

  statement {
    sid    = "AllowKMSForEKS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ListGrants",
      "kms:DescribeKey",
    ]
    resources = [var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn]
  }
}

resource "aws_iam_policy" "cluster_kms" {
  count = var.enable_cluster_encryption ? 1 : 0

  name   = "${var.cluster_name}-cluster-kms"
  policy = data.aws_iam_policy_document.cluster_kms[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_kms" {
  count = var.enable_cluster_encryption ? 1 : 0

  policy_arn = aws_iam_policy.cluster_kms[0].arn
  role       = aws_iam_role.cluster.name
}

################################################################################
# EKS Node Group IAM Role
################################################################################

data "aws_iam_policy_document" "node_group_assume_role" {
  statement {
    sid     = "EKSNodeGroupAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node_group" {
  for_each = var.managed_node_groups

  name = "${var.cluster_name}-${each.value.name}-node-role"
  path = "/"

  assume_role_policy    = data.aws_iam_policy_document.node_group_assume_role.json
  force_detach_policies = true

  tags = merge(var.tags, each.value.tags)
}

resource "aws_iam_role_policy_attachment" "node_group_worker" {
  for_each = var.managed_node_groups

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_group_cni" {
  for_each = var.managed_node_groups

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_group_ecr" {
  for_each = var.managed_node_groups

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_group_ssm" {
  for_each = var.managed_node_groups

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group[each.key].name
}

################################################################################
# EKS Fargate IAM Role
################################################################################

data "aws_iam_policy_document" "fargate_assume_role" {
  statement {
    sid     = "EKSFargateAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:fargateprofile/${var.cluster_name}/*"]
    }
  }
}

resource "aws_iam_role" "fargate" {
  name = "${var.cluster_name}-fargate-role"
  path = "/"

  assume_role_policy    = data.aws_iam_policy_document.fargate_assume_role.json
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}

################################################################################
# OIDC Provider for IRSA
################################################################################

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.eks[0].certificates[*].sha1_fingerprint
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = var.tags
}
