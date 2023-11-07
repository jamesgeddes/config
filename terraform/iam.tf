resource "aws_iam_role" "github_actions" {
  name               = "GithubActions"
  assume_role_policy = data.aws_iam_policy_document.github_allow.json
}

data "aws_iam_policy_document" "github_allow" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_oidc.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.owner}/*"]

    }
  }
}

data "aws_iam_policy_document" "assume_githubactions_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "iam:ListRolePolicies",
    ]
    resources = [aws_iam_role.github_actions.arn]
  }
}

resource "aws_iam_policy" "s3_readwrite" {
  name        = "s3-readwritedelete"
  path        = "/"
  description = "An IAM policy for S3 read-write access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "S3PermissionsForObjectOperations"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetBucketPolicy",
          "s3:CreateMultipartUpload",
          "s3:CreateMultipartUpload",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.tfstate.arn}/*",
        ]
      },
      {
        Sid = "S3PermissionsForBucketOperations"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketPolicy",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.tfstate.arn,
        ]
      },
    ]
  })

}

resource "aws_iam_policy" "oidc_read" {
  name        = "read-oidc"
  path        = "/"
  description = "Allow read of the GitHub OIDC provider"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "OIDCPermissions"
        Action = [
          "iam:GetOpenIDConnectProvider",
        ]
        Effect = "Allow"
        Resource = [
          aws_iam_openid_connect_provider.github_oidc.arn,
        ]
      },

    ]
  })
}

resource "aws_iam_policy" "iam_readwrite" {
  name        = "iam-readwrite"
  description = "Allow read of the GitHub OIDC provider"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "iamReadPolicyRole"
        Action = [
          "iam:GetPolicy",
          "iam:GetRole",
          "iam:GetPolicyVersion",
          "iam:ListAttachedRolePolicies",
          "iam:ListPolicyVersions",
        ]
        Effect = "Allow"
        Resource = [
          "*",
        ]
      },
      {
        Sid = "iamWritePolicy"
        Action = [
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:TagPolicy",
          "iam:DetachRolePolicy",
          "iam:DeletePolicyVersion",
        ]
        Effect = "Allow"
        Resource = [
          "*",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "assume_githubactions_policy" {
  name   = "AssumeGithubActionsPolicy"
  policy = data.aws_iam_policy_document.assume_githubactions_policy.json
}

resource "aws_iam_role_policy_attachment" "github_assume_role_policy_attachment" {
  policy_arn = aws_iam_policy.assume_githubactions_policy.arn
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_role_policy_attachment" {
  policy_arn = aws_iam_policy.s3_readwrite.arn
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "oidc_policy_attachment" {
  policy_arn = aws_iam_policy.oidc_read.arn
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "iam_read_policy_attachment" {
  policy_arn = aws_iam_policy.iam_readwrite.arn
  role       = aws_iam_role.github_actions.name
}
