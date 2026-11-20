output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "Map of private subnet IDs"
  value       = { for k, v in aws_subnet.private : k => v.id }
}

output "s3_gateway_endpoint_id" {
  description = "S3 VPC Gateway Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_gateway_endpoint_id" {
  description = "DynamoDB VPC Gateway Endpoint ID"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "dynamodb_table_name" {
  description = "DynamoDB tasks table name"
  value       = aws_dynamodb_table.tasks.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB tasks table ARN"
  value       = aws_dynamodb_table.tasks.arn
}

output "sqs_queue_url" {
  description = "Main SQS queue URL"
  value       = aws_sqs_queue.tasks.url
}

output "sqs_dlq_url" {
  description = "Dead Letter Queue URL"
  value       = aws_sqs_queue.dlq.url
}

output "worker_secret_arn" {
  description = "Secrets Manager secret ARN for worker parameters"
  value       = aws_secretsmanager_secret.worker_config.arn
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch Dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "backup_vault_name" {
  description = "AWS Backup Vault name"
  value       = aws_backup_vault.main.name
}