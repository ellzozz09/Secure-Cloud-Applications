# Security Compliance Matrix

**Project:** Secure Cloud Applications
**Environment:** Development (`depi-dev`)
**AWS Region:** `us-east-1`
**Owner:** Member 1 â€“ Security Architecture, IAM, WAF & Compliance

## 1. AWS Config Conformance Pack

The project uses five AWS-managed AWS Config rules to evaluate selected security controls.

| # | AWS Config Rule | Resource Type | What it checks | Expected compliant state |
|---|---|---|---|---|
| 1 | `DYNAMODB_TABLE_ENCRYPTION_ENABLED` | `AWS::DynamoDB::Table` | Whether DynamoDB tables have encryption enabled. | The table has encryption enabled. |
| 2 | `DYNAMODB_PITR_ENABLED` | `AWS::DynamoDB::Table` | Whether DynamoDB tables have point-in-time recovery enabled. | Point-in-time recovery is enabled. |
| 3 | `IAM_POLICY_NO_STATEMENTS_WITH_FULL_ACCESS` | `AWS::IAM::Policy` | Whether customer-managed IAM policies contain statements granting unrestricted service access. | No statement grants unrestricted service access. |
| 4 | `VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS` | `AWS::EC2::SecurityGroup` | Whether publicly accessible security groups expose inbound ports outside the authorized TCP port list. | No unrestricted public inbound access is allowed. |
| 5 | `SQS_QUEUE_NO_PUBLIC_ACCESS` | `AWS::SQS::Queue` | Whether an SQS queue policy allows public access. | The queue policy does not grant public access. |

## 2. Rule Limitations and Interpretation

- **DynamoDB encryption:** This rule evaluates encryption status; it does not independently prove every aspect of key-management governance.
- **DynamoDB PITR:** This rule checks point-in-time recovery, not the complete backup and disaster-recovery strategy.
- **IAM full access:** This rule evaluates customer-managed IAM policies. It does not represent a complete audit of inline policies or AWS-managed policies.
- **Security group ports:** This rule checks publicly accessible inbound ports. No public inbound ports are authorized for this project. It does not verify all outbound rules or prove that every security-group configuration is secure.
- **SQS public access:** This rule checks public access through queue policies. It does not replace a complete IAM authorization review.

A `COMPLIANT` result means the resource passed the specific rule's evaluation. It does not mean the entire resource or application is secure.

## 3. Secrets Manager Encryption â€“ Separate Verification

The implementation plan originally included a Secrets Manager customer-managed-key compliance check.

The team elected to retain the AWS-managed default KMS key for Secrets Manager instead of introducing a customer-managed KMS key.

The AWS Config rule `SECRETSMANAGER_USING_CMK` was therefore not selected: it specifically evaluates the use of a customer-managed KMS key and would not represent the chosen default-key design.

Instead:

- AWS Config records `AWS::SecretsManager::Secret` resources.
- Secrets Manager encryption is verified separately using the deployed secret's configuration and AWS evidence.
- The team must not report the `SECRETSMANAGER_USING_CMK` rule as passed or claim that the fifth conformance-pack rule checks Secrets Manager encryption.

**Documented deviation:** The fifth rule is `SQS_QUEUE_NO_PUBLIC_ACCESS`, replacing the originally proposed Secrets Manager customer-managed-key rule.

## 4. Evidence Collection

After deployment, collect the following evidence:

| Control | Evidence to collect |
|---|---|
| DynamoDB encryption | AWS Config evaluation result and DynamoDB table encryption configuration. |
| DynamoDB PITR | AWS Config evaluation result and DynamoDB PITR status. |
| IAM policy | AWS Config evaluation result and reviewed customer-managed IAM policy document. |
| Security group | AWS Config evaluation result and inbound security-group rules. |
| SQS public access | AWS Config evaluation result and SQS queue access policy. |
| Secrets Manager encryption | Secret configuration showing the encryption key selection, supported by AWS CLI or console evidence. |

For each AWS Config rule, record:

- Evaluation status (`COMPLIANT`, `NON_COMPLIANT`, or `NOT_APPLICABLE`).
- Resource identifier.
- Evaluation timestamp.
- Any non-compliance reason.
- Remediation action, if required.

## 5. Deployment and Reporting Status

The Terraform configuration and CloudFormation conformance-pack template have passed local validation.

The AWS Config recorder and conformance pack have not yet been deployed. Therefore, no live compliance evaluation results are available.

| Item | Current status |
|---|---|
| Conformance-pack template | Created and CloudFormation-validated |
| Terraform Config resources | Created and Terraform-validated |
| Terraform plan | Generated successfully; no resources applied |
| AWS Config recorder | Pending deployment |
| Conformance pack | Pending deployment |
| Live rule evaluations | Pending deployment and resource availability |
| Compliance evidence | Pending deployment and evaluation |

**Important:** Do not report any control as `COMPLIANT` until AWS Config has evaluated the deployed resource.
