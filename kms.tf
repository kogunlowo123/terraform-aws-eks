################################################################################
# KMS Key for EKS Envelope Encryption
################################################################################

resource "aws_kms_key" "eks" {
  count = var.enable_cluster_encryption && var.kms_key_arn == null ? 1 : 0

  description             = "KMS key for EKS cluster ${var.cluster_name} envelope encryption of Kubernetes secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key[0].json

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-encryption"
  })
}

resource "aws_kms_alias" "eks" {
  count = var.enable_cluster_encryption && var.kms_key_arn == null ? 1 : 0

  name          = "alias/eks/${var.cluster_name}"
  target_key_id = aws_kms_key.eks[0].key_id
}

data "aws_iam_policy_document" "kms_key" {
  count = var.enable_cluster_encryption && var.kms_key_arn == null ? 1 : 0

  statement {
    sid    = "KeyOwnerFullAccess"
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowEKSClusterRole"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cluster.arn]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.cluster_name}/*"]
    }
  }
}
