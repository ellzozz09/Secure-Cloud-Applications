# CI/CD Pipeline

## Scope

This document describes the current M5 pull-request security workflow in
`.github/workflows/ci-security.yml`. It is a CI validation workflow; it does
not deploy the application.

## Triggers

The workflow is configured to run for:

- Pull requests targeting `main`.
- Pushes to `main`.

There are no path filters, so changes in any part of the repository can trigger
these events. The jobs have no `needs` dependency and can run independently.

## CI jobs

### Gitleaks

The job checks out the full Git history and runs Gitleaks to look for exposed
secrets. Gitleaks comments are disabled. Credentials and tokens must not be
committed to the repository.

### Python security scans

The job uses Python 3.12.

- **Bandit** scans `src/` when Python source files are present.
- **pip-audit** audits each `requirements*.txt` file found in the repository.
- If the relevant source or requirements files are absent, the corresponding
  scan prints a notice and is skipped.

### Python unit tests

The job uses Python 3.12, installs discovered requirements files and `pytest`,
then runs `pytest -q` when Python test files are present under `tests/`.
If no test files are present, it prints a notice and skips the test run.
The test process removes AWS profile and credential variables, redirects AWS
configuration and shared-credentials files to `/dev/null`, and disables EC2
instance metadata. The test job does not configure AWS credentials; tests
should mock AWS operations and must not depend on live AWS access.

### Terraform validation

The job uses Terraform 1.16.3 and runs:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false -input=false -lockfile=readonly`
3. `terraform validate`

Initialization disables the configured remote backend and keeps the provider
lock file read-only. These checks validate formatting and configuration; they
do not run a Terraform plan.

## Permissions and AWS boundary

The workflow requests read access to repository contents and pull-request
metadata. The current CI jobs do not configure AWS credentials, request GitHub
OIDC tokens, or run AWS deployment commands.

`terraform plan` is not yet enabled. Before adding it, M1 must coordinate an
approved least-privilege OIDC role and the required Terraform state and locking
permissions for pull-request runs. CI must never run `terraform apply`.

## Deployment and security checks not covered by this workflow

The following are separate M5 deliverables and are not implemented by
`ci-security.yml`:

- `.github/workflows/deploy-apps.yml` is a manual, fail-closed deployment
  draft. It runs only from `main` after an explicit `DEPLOY` confirmation.
  It builds the Lambda ZIP and SHA-256 file, pushes the worker image, requires
  ECR scan-on-push, rejects High/Critical findings, signs and verifies the
  image with keyless Cosign, updates Lambda and ECS, and uploads provenance
  artifacts. It has not been executed. It requires the repository variables
  `AWS_DEPLOY_ROLE_ARN`, `ECR_REPOSITORY`, `LAMBDA_FUNCTION_NAME`,
  `ECS_CLUSTER_NAME`, `ECS_SERVICE_NAME`, and `ECS_CONTAINER_NAME`, along with
  the application and AWS resources. Running it changes resources in
  `us-east-1` and may incur cost; do not dispatch it until the role permissions,
  AWS impact, and cost have been reviewed.

  In this local snapshot, `src/api` and `src/worker/requirements.txt` are
  absent, so the deployment source preflight cannot pass. The Terraform
  OIDC trust is restricted to this repository's `main` branch, but not to
  `deploy-apps.yml`. The `github_oidc` role has a Terraform state/lock
  policy attached; no separate deployment role or ECR/Lambda/ECS deployment
  permissions were found in the reviewed Terraform files.
  `AWS_DEPLOY_ROLE_ARN` is a GitHub variable; its name alone does not
  establish that a suitable deployment role exists.
- **Not present or run in this local snapshot:** no DAST workflow or scan
  evidence exists. The workspace has no `src/` tree or OpenAPI spec, and no
  deployed test API or test-auth configuration was verified. Authenticated
  OWASP ZAP testing requires an OpenAPI spec, an authorized test target, and
  Cognito test-auth configuration.
- Redacted, reviewed scan reports under `docs/security/scan-reports/`.

The pull-request template is at `.github/pull_request_template.md`.
