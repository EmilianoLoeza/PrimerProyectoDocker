data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"

            "token.actions.githubusercontent.com:sub" = "repo:EmilianoLoeza@184412077/PrimerProyectoDocker@1430358073:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_name}-github-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
           "ecr:BatchCheckLayerAvailability",
           "ecr:BatchGetImage",
           "ecr:CompleteLayerUpload",
           "ecr:InitiateLayerUpload",
           "ecr:PutImage",
           "ecr:UploadLayerPart"
]

 

        Resource = aws_ecr_repository.app.arn
      },
      {
        Effect = "Allow"

        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]

        Resource = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-cluster/${var.project_name}-service"
      }
    ]
  })
}