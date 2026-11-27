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

## Third-party GitHub Actions pinning

Actions in the active CI workflow and the inert deployment reference are pinned
to full commit SHAs, with release versions in comments. Update pins through a
reviewed PR: confirm each SHA resolves to the intended release in the official
upstream repository, review the release notes and changes, update the SHA and
version comment together, and rerun checks. Do not use floating version tags.
The deployment reference under `docs/` is not loaded or executed by GitHub
Actions.

## Deployment and security checks not covered by this workflow

The following are separate M5 deliverables and are not implemented by
`ci-security.yml`:

- **No deployment workflow is active.** The previous draft is preserved at
  `docs/security/deferred-workflows/deploy-apps.yml.disabled`, outside
  `.github/workflows/`, so GitHub Actions will not load it. A separate
  `terraform/github_deploy_role.tf` draft defines an optional role with
  `enable_github_app_deploy_role = false` by default; it has passed local
  validation only and has not been applied. The draft role has no Terraform
  state permissions and is intended to be restricted to exact ECR, Lambda, ECS,
  and ECS task-role ARNs.
- Before any future deployment, the role and policy require security review.
  The GitHub OIDC trust expects the protected `m5-deploy` Environment, so that
  Environment must require an authorized reviewer and restrict deployments to
  `main`; the workflow job must declare `environment: m5-deploy`. Do not enable
  the role or run deployment until the prerequisites, permissions, AWS impact,
  and cost are reviewed.
- The deployment reference uses the planned `src/worker/Dockerfile` path with
  repository-root build context. The M4 snapshot inspected at commit `64c320f`
  instead has a root-level Dockerfile; confirm the final integrated path before
  restoring any deployment workflow.

- **Not present or run in this local snapshot:** no DAST workflow or scan
  evidence exists. The workspace has no `src/` tree or OpenAPI spec, and no
  deployed test API or test-auth configuration was verified. Authenticated
  OWASP ZAP testing requires an OpenAPI spec, an authorized test target, and
  Cognito test-auth configuration.
- Redacted, reviewed scan reports under `docs/security/scan-reports/`.

The pull-request template is at `.github/pull_request_template.md`.
