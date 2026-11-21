# 1. DynamoDB Table with Encryption, PITR & UserSubIndex GSI
resource "aws_dynamodb_table" "tasks" {
  name         = "depi-dev-tasks-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "task_id"

  attribute {
    name = "task_id"
    type = "S"
  }

  attribute {
    name = "user_sub"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name            = "UserSubIndex"
    hash_key        = "user_sub"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "depi-dev-tasks-table"
  }
}

# 2. Dead Letter Queue (DLQ)
resource "aws_sqs_queue" "dlq" {
  name                      = "depi-dev-tasks-dlq"
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name = "depi-dev-tasks-dlq"
  }
}

# 3. Standard SQS Queue with Encryption & Redrive Policy (maxReceiveCount = 3)
resource "aws_sqs_queue" "tasks" {
  name                       = "depi-dev-tasks-queue"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "depi-dev-tasks-queue"
  }
}

# 4. Secrets Manager Secret for Worker Runtime Parameters
resource "aws_secretsmanager_secret" "worker_config" {
  name        = "${var.project_name}/worker/runtime-config"
  description = "Runtime configuration parameters for worker service"
}

resource "aws_secretsmanager_secret_version" "worker_config_val" {
  secret_id = aws_secretsmanager_secret.worker_config.id
  secret_string = jsonencode({
    QUEUE_NAME       = aws_sqs_queue.tasks.name
    DLQ_NAME         = aws_sqs_queue.dlq.name
    DYNAMODB_TABLE   = aws_dynamodb_table.tasks.name
    AWS_REGION       = var.aws_region
    MAX_BATCH_SIZE   = 10
    POLL_WAIT_SECOND = 20
  })
}

# 5. AWS Backup Vault & Daily Backup Plan for DynamoDB Table
resource "aws_backup_vault" "main" {
  name = "${var.project_name}-backup-vault"
}

data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup" {
  name               = "${var.project_name}-aws-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_plan" "daily_dynamodb" {
  name = "${var.project_name}-daily-dynamodb-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)" # Daily at 02:00 UTC

    lifecycle {
      delete_after = 14
    }
  }
}

resource "aws_backup_selection" "dynamodb_tasks" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.project_name}-dynamodb-backup-selection"
  plan_id      = aws_backup_plan.daily_dynamodb.id

  resources = [
    aws_dynamodb_table.tasks.arn
  ]
}
