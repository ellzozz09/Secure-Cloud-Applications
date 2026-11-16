# STRIDE Threat Model

## 1. Document Information

| Item | Description |
|---|---|
| Project | Secure Cloud Applications, DevOps & Compliance by Design |
| Application | Cloud-Native Background Task Manager |
| Owner | Member 1 — Security Architecture |
| Methodology | STRIDE |
| AWS Region | `us-east-1` |
| Status | Initial design; review as implementation evolves |

## 2. System Overview

The application allows authenticated users to submit background tasks through an API. The API validates and authorizes requests, stores task information in DynamoDB, and sends messages to Amazon SQS. An Amazon ECS Fargate worker consumes messages and updates task status.

### Main components

- **Amazon Cognito:** user authentication and identity.
- **AWS WAF:** filters malicious HTTP requests before they reach the API.
- **Amazon API Gateway:** exposes the application's HTTP API.
- **AWS Lambda:** validates and processes API requests.
- **Amazon DynamoDB:** stores task records.
- **Amazon SQS:** queues background-task messages.
- **Amazon ECS Fargate:** runs the background worker.
- **AWS Secrets Manager:** stores worker secrets.
- **Amazon CloudWatch and AWS X-Ray:** provide logs, monitoring, and tracing.
- **AWS IAM:** controls permissions between application components.

## 3. Data Flow and Trust Boundaries

### Boundary 1 — Client to WAF / API Gateway

**Flow:** Client → AWS WAF → API Gateway

The client communicates with the public API endpoint. WAF inspects incoming HTTP requests before API Gateway processes them.

Security concerns:
- Requests may come from malicious or unauthorized clients.
- Attackers may attempt injection, malformed requests, or excessive requests.
- Authentication tokens may be stolen or misused.

Planned controls:
- Require valid Cognito authentication for protected API operations.
- Use AWS WAF managed rules, including Common Rule Set, Known Bad Inputs, and SQL injection protections.
- Configure IP-based rate limiting.
- Enforce HTTPS.
- Validate authorization claims before allowing access to protected operations.

### Boundary 2 — API Gateway to Lambda

**Flow:** API Gateway → AWS Lambda

API Gateway invokes Lambda to process application requests. This is a service-to-service boundary where the API must invoke only the intended function and the function must validate incoming data.

Security concerns:
- Unauthorized or unintended function invocation.
- Malformed or manipulated request data.
- Excessive requests causing resource exhaustion.
- Excessive Lambda permissions allowing unintended access.

Planned controls:
- Restrict Lambda invocation permissions to the intended API Gateway.
- Validate request bodies, parameters, and identity claims in the API handler.
- Apply authorization checks before accessing user-owned tasks.
- Use a dedicated Lambda execution role with only the required DynamoDB, SQS, logging, and tracing permissions.
- Configure appropriate API throttling and WAF rate limits.

### Boundary 3 — Lambda to DynamoDB / SQS

**Flow:** Lambda → DynamoDB and Lambda → SQS

Lambda stores task information in DynamoDB and sends background-task messages to SQS.

Security concerns:
- Unauthorized reading or modification of task records.
- Access to another user's task data.
- Message tampering or malformed queue messages.
- Excessive permissions allowing destructive database or queue operations.
- Sensitive information accidentally included in messages or logs.

Planned controls:
- Use a dedicated Lambda IAM role.
- Scope DynamoDB permissions to the application task table and required index.
- Grant only the required actions, such as `PutItem`, `GetItem`, `Query`, and `UpdateItem`.
- Grant `sqs:SendMessage` only on the application queue.
- Do not grant the Lambda role unnecessary permissions such as `dynamodb:Scan`, `dynamodb:DeleteTable`, or `sqs:ReceiveMessage`.
- Validate task ownership and message structure.
- Avoid placing secrets or unnecessary personal data in queue messages.
- Enable DynamoDB encryption at rest and point-in-time recovery.

### Boundary 4 — ECS Fargate Worker to AWS Services

**Flow:** ECS Fargate worker → SQS / DynamoDB / Secrets Manager

The worker runs in public subnets as part of the cost-conscious deployment design. Its security group has no inbound rules and permits outbound TCP port 443 only. The worker receives messages from SQS, processes tasks, and updates task records in DynamoDB. Its required secret is retrieved through its execution-role configuration.

Security concerns:
- Unauthorized inbound access to the worker.
- Compromised worker attempting to access unrelated AWS resources.
- Malicious or malformed queue messages.
- Exposure of secrets or sensitive task data.
- Excessive worker permissions.
- Vulnerable or tampered container images.

Planned controls:
- Configure the worker security group with zero inbound rules and outbound TCP 443 only.
- Use separate ECS execution and worker task roles.
- Limit the execution role to image-pull, logging, and required secret-retrieval permissions.
- Limit the worker task role to required SQS receive/delete/visibility actions, scoped DynamoDB read/update actions, and tracing.
- Do not grant the worker task role ECR pull or Secrets Manager access unless the architecture is explicitly revised.
- Scan container images and use immutable image tags.
- Run the container as a non-root user with a read-only root filesystem where supported.
- Validate messages before processing and handle failures through the SQS dead-letter queue.
- Do not expose DynamoDB or SQS publicly.

## 4. STRIDE Threat Analysis

| STRIDE Category | Example Threat | Potential Impact | Planned Mitigation |
|---|---|---|---|
| **Spoofing** | An attacker uses a stolen or forged identity token to impersonate a user. | Unauthorized access to user tasks. | Cognito authentication, token validation, HTTPS, and authorization checks. |
| **Tampering** | An attacker modifies request data or submits a manipulated queue message. | Incorrect task execution or unauthorized data changes. | Input validation, scoped IAM permissions, controlled API access, and message validation. |
| **Repudiation** | A user denies submitting a task or an administrator cannot determine which component performed an action. | Insufficient accountability during investigations. | CloudWatch logs, API access logging, correlation identifiers, and audit-relevant AWS events. |
| **Information Disclosure** | A user accesses another user's task, or sensitive values appear in logs or container configuration. | Exposure of private or operational information. | Ownership checks, least-privilege IAM, encryption, Secrets Manager, and careful log handling. |
| **Denial of Service** | An attacker floods the API or causes repeated worker failures. | Increased cost, unavailable API, or delayed task processing. | AWS WAF rate-based rules, API throttling, queue buffering, worker failure handling, and SQS dead-letter queue. |
| **Elevation of Privilege** | A compromised Lambda or worker uses an overly permissive IAM role to access unrelated resources. | Broader compromise of the AWS environment. | Separate service roles, resource-scoped policies, IAM policy validation, and denial of unnecessary actions. |

## 5. IAM Separation and Least Privilege

The application uses separate IAM roles so that compromise of one component does not automatically grant the permissions of another.

| IAM Role | Intended Responsibility | Important Restrictions |
|---|---|---|
| `depi-dev-lambda-api-role` | Lambda API access to task records and sending messages to SQS. | No `dynamodb:Scan`, table deletion, SQS message consumption, or broad IAM permissions. |
| `depi-dev-ecs-execution-role` | ECS image retrieval, log setup, and required startup secret retrieval. | No runtime DynamoDB or SQS permissions. |
| `depi-dev-ecs-worker-task-role` | Worker consumption of SQS messages and task record updates. | No ECR image pull, Secrets Manager access, or DynamoDB item creation/deletion. |
| `depi-dev-apigw-logs-role` | API Gateway access logging to CloudWatch. | No application data, SQS, ECR, or Secrets Manager permissions. |
| `depi-dev-github-oidc-role` | GitHub Actions access through OIDC for approved CI operations. | No static AWS access keys and no CI `terraform apply`. Trust restricted to the project repository. |

The exact permissions must be verified against the deployed Terraform policies and the application's actual resource ARNs.

## 6. Monitoring and Detection

The following services support security monitoring and incident investigation:

- **AWS CloudTrail:** records relevant AWS API activity.
- **Amazon CloudWatch Logs:** stores application and API logs.
- **Amazon CloudWatch Metrics and Alarms:** help identify abnormal request volume and service failures.
- **AWS X-Ray:** supports tracing requests across application components.
- **AWS Config:** evaluates selected resource configuration rules and detects configuration drift.
- **Amazon SQS DLQ:** retains messages that repeatedly fail processing for investigation.

Logs must not contain passwords, access tokens, secret values, or unnecessary personal information.

## 7. Residual Risks and Assumptions

1. The threat model describes the planned architecture and must be updated when implementation changes.
2. Cognito token validation and user-to-task ownership enforcement must be verified in the API implementation.
3. WAF rules and rate limits require testing to reduce false positives and confirm that malicious requests are blocked.
4. A public-subnet ECS deployment is not equivalent to a private-subnet deployment. The worker security group and IAM restrictions must be verified carefully.
5. Container scanning reduces but does not eliminate the risk of vulnerable dependencies or images.
6. AWS Config checks provide configuration evidence; they do not by themselves establish GDPR, HIPAA, or PCI-DSS compliance.
7. Secrets rotation, backup recovery, and incident response require operational testing.

## 8. Review and Validation Checklist

- Confirm the four data-flow boundaries match the deployed architecture.
- Verify Cognito authentication and API authorization.
- Verify WAF managed rules and rate-based rules.
- Review Lambda, ECS execution, ECS task, API Gateway logging, and GitHub OIDC roles.
- Confirm the worker security group has no inbound rules and only the intended outbound access.
- Confirm DynamoDB and SQS are not publicly exposed.
- Confirm CloudWatch logging and X-Ray tracing are configured.
- Review the model with Members 2, 3, 4, and 5.
- Update this document after material architecture or permission changes.

**Document owner:** Member 1 — Security Architecture, IAM, WAF & Compliance.
