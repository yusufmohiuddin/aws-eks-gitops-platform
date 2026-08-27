resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  tags = merge(local.common_tags, {
    Name = "github-actions"
  })
}

data "aws_iam_policy_document" "github_ecr_publish_assume_role" {
  statement {
    sid     = "GitHubMainBranch"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${var.github_oidc_subject_prefix}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_ecr_publisher" {
  name                 = "${local.name}-ecr-publisher"
  description          = "Publishes verified reference-service images from GitHub Actions"
  assume_role_policy   = data.aws_iam_policy_document.github_ecr_publish_assume_role.json
  max_session_duration = 3600

  tags = local.common_tags
}

data "aws_iam_policy_document" "github_ecr_publish" {
  statement {
    sid       = "AuthenticateToECR"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PublishReferenceService"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [module.ecr.repository_arn]
  }
}

resource "aws_iam_role_policy" "github_ecr_publish" {
  name   = "ecr-publish"
  role   = aws_iam_role.github_ecr_publisher.id
  policy = data.aws_iam_policy_document.github_ecr_publish.json
}
