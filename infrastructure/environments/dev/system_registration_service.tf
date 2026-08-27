module "system_registration_ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name                 = "system-registration-service"
  repository_type                 = "private"
  repository_image_tag_mutability = "IMMUTABLE"

  attach_repository_policy      = false
  create_repository_policy      = false
  repository_image_scan_on_push = true
  repository_encryption_type    = "AES256"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after one day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Retain the most recent twenty release images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = { type = "expire" }
      },
    ]
  })

  tags = local.common_tags
}

data "aws_iam_policy_document" "system_registration_assume_role" {
  statement {
    sid     = "SystemRegistrationMainBranch"
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
      values   = ["${var.system_registration_github_oidc_subject_prefix}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "system_registration_publisher" {
  name                 = "${local.name}-system-registration-publisher"
  description          = "Publishes verified system-registration-service images from GitHub Actions"
  assume_role_policy   = data.aws_iam_policy_document.system_registration_assume_role.json
  max_session_duration = 3600
  tags                 = local.common_tags
}

data "aws_iam_policy_document" "system_registration_publish" {
  statement {
    sid       = "AuthenticateToECR"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PublishSystemRegistrationService"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [module.system_registration_ecr.repository_arn]
  }
}

resource "aws_iam_role_policy" "system_registration_publish" {
  name   = "ecr-publish"
  role   = aws_iam_role.system_registration_publisher.id
  policy = data.aws_iam_policy_document.system_registration_publish.json
}
