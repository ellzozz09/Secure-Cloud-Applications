# Optional GitHub Actions application-deployment role.
# Disabled by default; it has no Terraform-state permissions.
variable "enable_github_app_deploy_role" {
  description = "Create a separate application deployment role only after review."
  type        = bool
  default     = false
}

variable "github_app_deploy_environment" {
  description = "Protected GitHub Environment used by the deployment workflow."
  type        = string
  default     = "m5-deploy"
}

variable "github_deploy_ecr_repository_arn" {
  description = "Exact ECR repository ARN; required only when the role is enabled."
  type        = string
  default     = ""
}

variable "github_deploy_lambda_function_arn" {
  description = "Exact Lambda function ARN; required only when the role is enabled."
  type        = string
  default     = ""
}

variable "github_deploy_ecs_cluster_arn" {
  description = "Exact ECS cluster ARN; required only when the role is enabled."
  type        = string
  default     = ""
}

variable "github_deploy_ecs_service_arn" {
  description = "Exact ECS service ARN; required only when the role is enabled."
  type        = string
  default     = ""
}

variable "github_deploy_ecs_task_definition_family_arn" {
  description = "Unrevisioned ARN for the one ECS task-definition family."
  type        = string
  default     = ""
}

resource "aws_iam_role" "github_app_deploy" {
  count = var.enable_github_app_deploy_role ? 1 : 0

  name                 = "${var.project_name}-github-app-deploy-role"
  description          = "GitHub Actions application deployment; no Terraform state access."
  max_session_duration = 3600

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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:environment:${var.github_app_deploy_environment}"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-app-deploy-role"
  }
}

resource "aws_iam_policy" "github_app_deploy" {
  count = var.enable_github_app_deploy_role ? 1 : 0

  name        = "${var.project_name}-github-app-deploy"
  description = "Scoped ECR, Lambda, and ECS deployment permissions for GitHub Actions."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuthorization"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "PushAndScanConfiguredRepository"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImageScanFindings",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = var.github_deploy_ecr_repository_arn
      },
      {
        Sid    = "UpdateConfiguredLambdaCode"
        Effect = "Allow"
        Action = [
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionCode"
        ]
        Resource = var.github_deploy_lambda_function_arn
      },
      {
        Sid      = "DescribeConfiguredEcsServiceAndCluster"
        Effect   = "Allow"
        Action   = ["ecs:DescribeServices"]
        Resource = [var.github_deploy_ecs_service_arn, var.github_deploy_ecs_cluster_arn]
      },
      {
        Sid    = "UpdateConfiguredEcsService"
        Effect = "Allow"
        Action = ["ecs:UpdateService"]
        Resource = [
          var.github_deploy_ecs_service_arn
        ]
      },
      {
        Sid    = "RegisterOnlyConfiguredTaskFamily"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "${var.github_deploy_ecs_task_definition_family_arn}:*"
      },
      {
        Sid      = "PassOnlyEcsTaskRoles"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [aws_iam_role.ecs_execution.arn, aws_iam_role.ecs_worker_task.arn]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })

  lifecycle {
    precondition {
      condition = alltrue([
        can(regex("^arn:aws:ecr:[^:]+:[0-9]{12}:repository/[^*?]+$", var.github_deploy_ecr_repository_arn)),
        can(regex("^arn:aws:lambda:[^:]+:[0-9]{12}:function:[^*?]+$", var.github_deploy_lambda_function_arn)),
        can(regex("^arn:aws:ecs:[^:]+:[0-9]{12}:cluster/[^*?]+$", var.github_deploy_ecs_cluster_arn)),
        can(regex("^arn:aws:ecs:[^:]+:[0-9]{12}:service/[^/]+/[^*?]+$", var.github_deploy_ecs_service_arn)),
        can(regex("^arn:aws:ecs:[^:]+:[0-9]{12}:task-definition/[^/:*?]+$", var.github_deploy_ecs_task_definition_family_arn))
      ])
      error_message = "Enabling the deployment role requires exact, non-wildcard ARNs for the configured ECR repository, Lambda function, ECS cluster/service, and ECS task-definition family."
    }
  }

  tags = {
    Name = "${var.project_name}-github-app-deploy"
  }
}

resource "aws_iam_role_policy_attachment" "github_app_deploy" {
  count = var.enable_github_app_deploy_role ? 1 : 0

  role       = aws_iam_role.github_app_deploy[0].name
  policy_arn = aws_iam_policy.github_app_deploy[0].arn
}

output "github_app_deploy_role_arn" {
  description = "ARN of the optional GitHub application-deployment role; null while disabled."
  value       = try(aws_iam_role.github_app_deploy[0].arn, null)
}
