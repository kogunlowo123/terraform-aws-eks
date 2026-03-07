################################################################################
# IAM Role for Service Account (IRSA)
################################################################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AssumeRoleWithWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = var.assume_role_condition_test
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = [for sa in var.service_accounts : "system:serviceaccount:${sa.namespace}:${sa.name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  path                 = var.role_path
  max_session_duration = var.max_session_duration
  description          = var.role_description

  assume_role_policy    = data.aws_iam_policy_document.assume_role.json
  force_detach_policies = true
  permissions_boundary  = var.permissions_boundary_arn

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.policy_arns)

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

resource "aws_iam_policy" "inline" {
  count = var.inline_policy != null ? 1 : 0

  name   = "${var.role_name}-inline"
  policy = var.inline_policy

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "inline" {
  count = var.inline_policy != null ? 1 : 0

  policy_arn = aws_iam_policy.inline[0].arn
  role       = aws_iam_role.this.name
}
