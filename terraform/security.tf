# ---------------------------------------------------------
# GitHub Actions OIDC Identity Provider
# ---------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name = "${var.project_name}-github-oidc"
  }
}

# ---------------------------------------------------------
# GitHub Actions IAM Role
# ---------------------------------------------------------

resource "aws_iam_role" "github_oidc" {
  name = "${var.project_name}-github-oidc-role"

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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-oidc-role"
  }
}

# ---------------------------------------------------------
# GitHub Actions Terraform State Policy
# ---------------------------------------------------------

resource "aws_iam_policy" "github_terraform_state" {
  name        = "${var.project_name}-github-terraform-state"
  description = "Restricted Terraform remote state access for GitHub Actions."

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid      = "ListTerraformStatePath"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::depi-team-3-tfstate"

        Condition = {
          StringLike = {
            "s3:prefix" = [
              "project/terraform.tfstate"
            ]
          }
        }
      },
      {
        Sid    = "ReadTerraformState"
        Effect = "Allow"
        Action = ["s3:GetObject"]

        Resource = "arn:aws:s3:::depi-team-3-tfstate/project/terraform.tfstate"
      },
      {
        Sid    = "ManageTerraformStateLock"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "arn:aws:s3:::depi-team-3-tfstate/project/terraform.tfstate.tflock"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-terraform-state"
  }
}

resource "aws_iam_role_policy_attachment" "github_terraform_state" {
  role       = aws_iam_role.github_oidc.name
  policy_arn = aws_iam_policy.github_terraform_state.arn
}

# ---------------------------------------------------------
# Lambda API Execution Role
# ---------------------------------------------------------

resource "aws_iam_role" "lambda_api" {
  name = "${var.project_name}-lambda-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-lambda-api-role"
  }
}

# ---------------------------------------------------------
# Lambda API CloudWatch Logs Policy
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------------------
# Lambda API X-Ray Policy
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_api.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# ---------------------------------------------------------
# ECS Task Execution Role
# ---------------------------------------------------------

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

# ---------------------------------------------------------
# ECS Worker Task Role
# ---------------------------------------------------------

resource "aws_iam_role" "ecs_worker_task" {
  name = "${var.project_name}-ecs-worker-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-worker-task-role"
  }
}

# ---------------------------------------------------------
# API Gateway CloudWatch Logs Role
# ---------------------------------------------------------

resource "aws_iam_role" "apigw_logs" {
  name = "${var.project_name}-apigw-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "apigateway.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-apigw-logs-role"
  }
}

resource "aws_iam_role_policy_attachment" "apigw_logs" {
  role       = aws_iam_role.apigw_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}