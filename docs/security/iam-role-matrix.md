# IAM Role-Permission Matrix

**Project:** Secure Cloud Applications, DevOps & Compliance by Design
**Team:** DEPI Team 3
**Region:** us-east-1
**Status:** Initial design — pending resource integration and validation

## 1. Purpose

This document defines the five isolated IAM roles used by the application. Each role must have only the permissions required for its responsibility.

Resource-specific permissions will be scoped to actual AWS ARNs after the corresponding infrastructure resources are implemented.

## 2. IAM Role Matrix

| IAM Role | Trusted Principal | Responsibility |
|---|---|---|
| `depi-dev-github-oidc-role` | GitHub OIDC | Authenticate GitHub Actions and perform approved CI/CD operations |
| `depi-dev-lambda-api-role` | `lambda.amazonaws.com` | Allow the API Lambda function to access application data and send messages |
| `depi-dev-ecs-execution-role` | `ecs-tasks.amazonaws.com` | Pull container images, initialize logging, and retrieve startup secrets |
| `depi-dev-ecs-worker-task-role` | `ecs-tasks.amazonaws.com` | Allow the worker to consume SQS messages and update task records |
| `depi-dev-apigw-logs-role` | `apigateway.amazonaws.com` | Publish API Gateway logs to CloudWatch |

## 3. Detailed Permissions

### 3.1 GitHub OIDC Role

**Allowed:**
- Assume the role through GitHub OIDC, restricted to the repository's `main` branch.
- `s3:ListBucket` on the Terraform state bucket, restricted to the state prefix.
- `s3:GetObject` on the Terraform state object.
- `s3:GetObject`, `s3:PutObject`, and `s3:DeleteObject` on the Terraform lock file.
- Future approved CI/CD permissions for read-only plan inspection, ECR image publishing, and Lambda/ECS code updates.

**Prohibited:**
- Static IAM user credentials.
- Terraform `apply` from CI/CD.
- Unrestricted repository trust.
- Write access to the Terraform state object.

**Status:** OIDC provider, trust policy, and Terraform state policy implemented. Additional CI/CD permissions pending Member 5's workflow design.

### 3.2 Lambda API Execution Role

**Allowed:**
- DynamoDB: `PutItem`, `GetItem`, `Query`, `UpdateItem`.
- SQS: `SendMessage`.
- CloudWatch Logs write operations.
- AWS X-Ray write operations.

**Resource scope:**
- `depi-dev-tasks-table` and its `UserSubIndex` index.
- `depi-dev-tasks-queue`.

**Prohibited:**
- `dynamodb:DeleteTable`.
- `dynamodb:Scan`.
- `sqs:ReceiveMessage`.
- `iam:*`.
- `secretsmanager:*`.

**Status:** Role, CloudWatch Logs attachment, and X-Ray attachment implemented. DynamoDB and SQS permissions pending resource definitions.

### 3.3 ECS Task Execution Role

**Allowed:**
- `ecr:GetAuthorizationToken` for ECR authentication.
- ECR image-pull operations scoped to the project's ECR repository.
- CloudWatch log stream creation.
- `secretsmanager:GetSecretValue` on the worker's specific secret.

**Prohibited:**
- Runtime DynamoDB permissions.
- Runtime SQS permissions.

**Status:** Role implemented. Resource-specific permissions pending ECR repository and Secrets Manager definitions.

### 3.4 ECS Worker Task Role

**Allowed:**
- SQS: `GetQueueUrl`, `ReceiveMessage`, `DeleteMessage`.
- DynamoDB: `UpdateItem`.
- AWS X-Ray: `PutTraceSegments`, `PutTelemetryRecords`.

**Resource scope:**
- `depi-dev-tasks-queue` for SQS operations.
- `depi-dev-tasks-table` for DynamoDB operations.
- X-Ray write permissions as required by the AWS service.

**Prohibited:**
- ECR pull permissions.
- `secretsmanager:*`.
- `dynamodb:DeleteItem`.
- `dynamodb:GetItem`.
- `dynamodb:PutItem`.
- `sqs:ChangeMessageVisibility`.

**Status:** Role implemented. Application permissions pending resource definitions and Terraform policy integration.

### 3.5 API Gateway Logging Role

**Allowed:**
- `AmazonAPIGatewayPushToCloudWatchLogs` managed policy.

**Prohibited:**
- DynamoDB permissions.
- SQS permissions.
- ECR permissions.
- Secrets Manager permissions.
- IAM administration permissions.

**Status:** Role and managed policy attachment implemented.

## 4. Implementation and Validation Status

| Item | Status |
|---|---|
| GitHub OIDC provider | Implemented |
| GitHub OIDC role | Implemented |
| Terraform state policy | Implemented |
| Lambda API role | Implemented |
| Lambda CloudWatch Logs | Implemented |
| Lambda X-Ray | Implemented |
| ECS execution role | Implemented |
| ECS worker task role | Implemented |
| API Gateway logging role | Implemented |
| Lambda DynamoDB/SQS permissions | Pending |
| ECS execution ECR/Secrets permissions | Pending |
| ECS worker SQS/DynamoDB/X-Ray permissions | Pending |
| IAM Policy Simulator testing | Pending |

## 5. Security Principles

1. Separate execution roles from runtime task roles.
2. Grant permissions only to the AWS resources that require them.
3. Avoid wildcard resource permissions wherever AWS supports resource-level scoping.
4. Never store static AWS credentials in the repository or container images.
5. Do not grant CI/CD permission to execute Terraform apply.
6. Validate permissions against the actual deployed resources before final deployment.

**Important:** This is the initial IAM design. Pending permissions must not be treated as implemented or verified until their resource definitions, policies, and tests are complete.