# Secrets Management Plan

## Status and scope

This document defines the intended secrets-management controls for the project.
It is a plan, not evidence that AWS resources have been deployed or that runtime
integration has been tested.

The design includes AWS Secrets Manager, AWS KMS, Lambda, ECS Fargate, and
GitHub Actions. The exact secret names, IAM policies, rotation configuration,
and service integrations must be verified during implementation.

## What counts as a secret

Examples include passwords, private keys, API tokens, and credentials for
dedicated test accounts. Resource names, AWS regions, and Cognito app client IDs
are generally configuration identifiers, not secrets.

Do not commit secret values to Git or store them in source code, Docker images,
Terraform files, test fixtures, CI logs, or scan reports.

## Storage and runtime access

### AWS application services

- Use AWS Secrets Manager as the intended store for application secrets.
- Secrets Manager encrypts stored secret values with AWS KMS. Use the default
  AWS-managed key unless the project establishes and configures a need for a
  customer-managed key.
- Grant each workload access only to the specific secret ARNs it requires.
  Avoid broad `secretsmanager:*` permissions and do not share one workload's
  credentials with another.
- Lambda should retrieve only its required secret using its Lambda execution
  role. Avoid embedding secret values in source code or Lambda deployment
  packages.
- For ECS Fargate, choose the retrieval method deliberately:
  - If the worker retrieves secrets at runtime, grant the ECS task role access
    only to the required secret.
  - If ECS injects a secret into the container from its task definition, grant
    the ECS task execution role only the permissions needed for that mechanism.
    Do not confuse the task execution role with the application task role.
- DynamoDB and SQS access should use workload IAM roles, not embedded AWS
  access keys.

Do not log secret values, authorization headers, session tokens, or full
credential-bearing request bodies. Review exception handling and diagnostic
logging for accidental disclosure.

## GitHub Actions and Terraform

- Do not create or commit long-lived AWS access keys for GitHub Actions.
- The current M5 CI workflow does not authenticate to AWS. Any future AWS
  workflow must use GitHub OIDC with a least-privilege role and a trust policy
  reviewed with M1 before it is enabled.
- Future authenticated DAST tests should use a dedicated non-production test
  account. Store required test credentials as protected GitHub Actions
  environment secrets; never print them or save access tokens as artifacts.
  Do not expose those secrets to untrusted fork pull requests.
- Do not put secret values in Terraform configuration or variables. Marking a
  Terraform value `sensitive` hides some command output but does not keep the
  value out of Terraform state.
- The repository's Terraform backend configuration requests S3 encryption, but
  configuration alone does not prove that the state bucket exists or that its
  encryption, access policy, and locking have been verified. Treat the entire
  Terraform state as sensitive and keep secret values out of it.

## Secret lifecycle

1. **Create:** Assign an owner and purpose. Generate secrets using an approved
   mechanism; do not place generated values in PR descriptions or chat.
2. **Store:** Put application secrets in Secrets Manager and restrict access
   with IAM. Use protected GitHub environment secrets only for CI test
   credentials that cannot use a safer non-secret test mechanism.
3. **Use:** Retrieve secrets only at runtime or through an explicitly reviewed
   service-integration mechanism. Keep them out of logs, command-line
   arguments, and build artifacts.
4. **Rotate:** Automate rotation where supported and tested. For other
   credentials, define an owner and rotation procedure appropriate to the
   credential. Coordinate rotation with dependent services and test the new
   value before retiring the old one.
5. **Revoke and remove:** Revoke credentials that are retired or suspected to
   be exposed. Removing a value from the latest Git revision does not make an
   exposed credential safe; rotate or revoke it.

## Auditing and incident response

- Verify that AWS audit logging records relevant Secrets Manager and KMS access
  events, and define who reviews suspicious access.
- If a secret is exposed, revoke or rotate it promptly; identify the affected
  services and time window; review relevant audit and application logs; and
  document the response without copying the exposed value into the incident
  record.
- Use Gitleaks to help detect accidental secret commits. A clean scan does not
  prove that no secret was exposed, and a scan does not replace credential
  rotation.

## Implementation checklist

- [ ] List each required secret, its purpose, owner, consumers, and rotation
      method without recording its value in this document.
- [ ] Confirm the Secrets Manager and KMS configuration before deployment.
- [ ] Review Lambda execution-role and ECS task/task-execution-role permissions.
- [ ] Verify that Terraform plans, state, logs, and artifacts do not expose
      secret values.
- [ ] Configure and test the approved audit and rotation procedures.
- [ ] Create dedicated non-production DAST test credentials only when the DAST
      workflow is ready.
- [ ] Recheck this plan after application integrations are implemented.

## Current verification status

This document records intended controls only. It does not claim that
Secrets Manager, KMS keys, IAM access policies, secret rotation, or AWS audit
logging have been deployed or tested.
