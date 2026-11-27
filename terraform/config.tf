data "aws_caller_identity" "current" {}

# ---------------------------------------------------------
# AWS Config - Dedicated S3 delivery bucket
# ---------------------------------------------------------

resource "aws_s3_bucket" "config" {
  bucket        = "depi-team-3-config-212810920501-us-east-1"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-config-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.config.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.config
  ]
}

# ---------------------------------------------------------
# AWS Config - Recorder role
# ---------------------------------------------------------

resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"
}

# ---------------------------------------------------------
# AWS Config - Selective resource recording
# ---------------------------------------------------------

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-recorder"
  role_arn = aws_iam_service_linked_role.config.arn

  recording_group {
    all_supported = false

    resource_types = [
      "AWS::DynamoDB::Table",
      "AWS::IAM::Policy",
      "AWS::EC2::SecurityGroup",
      "AWS::SQS::Queue",
      "AWS::SecretsManager::Secret"
    ]
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config.bucket

  depends_on = [
    aws_config_configuration_recorder.main,
    aws_s3_bucket_policy.config
  ]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.main
  ]
}

# ---------------------------------------------------------
# AWS Config - Five-rule security Conformance Pack
# ---------------------------------------------------------

resource "aws_config_conformance_pack" "security_baseline" {
  name = "${var.project_name}-security-baseline"

  template_body = file("${path.module}/../compliance/conformance-pack.yaml")

  depends_on = [
    aws_config_configuration_recorder_status.main
  ]
}
