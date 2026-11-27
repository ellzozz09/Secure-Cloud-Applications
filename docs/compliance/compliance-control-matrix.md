# Compliance Control Matrix — Engineering Crosswalk

## Purpose and limitations

This is an illustrative engineering crosswalk for selected controls in GDPR,
the HIPAA Security Rule, and PCI DSS v4.0.1. It is not legal advice, a formal
compliance assessment, an attestation, or a claim of certification.

The project's data-processing scope has not been established here. Whether
GDPR, HIPAA, or PCI DSS applies depends on the actual data, users, services,
and organizational roles. In particular, no evidence reviewed for this
crosswalk establishes that the application processes personal data, ePHI, or
cardholder data.

A control reference below indicates a possible relationship, not that the
project satisfies the referenced law or standard. Confirm applicability and
interpretation with the relevant privacy/security owner and, where applicable,
a qualified assessor.

## Status definitions

- **Documented in main:** A related repository document or Terraform
  configuration is present in the reviewed `main` snapshot. This does not
  prove deployment or runtime effectiveness.
- **Local M5 draft/test:** A file or test exists only in the local M5 working
  tree or a disposable test copy; it has not been verified by GitHub Actions.
- **PR-only:** The evidence is in a pull request, not in merged `main`.
- **Not evidenced:** No implementation or operational evidence was identified
  in the reviewed repository snapshot.
- **Live verification pending:** AWS deployment and operational evidence have
  not been established.

## Selected control crosswalk

| Control area | Illustrative references | Evidence observed | Status and limitation |
|---|---|---|---|
| Identity and least privilege | GDPR Articles 25 and 32; HIPAA 45 CFR §164.312(a)(1) and (d); PCI DSS v4.0.1 Requirements 7 and 8 | `docs/security/iam-role-matrix.md` and `terraform/security.tf` are in the reviewed `main` snapshot. | **Documented in main; live verification pending.** The repository documents IAM/OIDC design, not a deployed access review. The inspected OIDC trust was restricted to the `main` branch. Application-level Cognito/API authorization was not evidenced in that snapshot. |
| Web perimeter protection | GDPR Article 32; PCI DSS Requirements 1 and, where applicable, 6.4.2 | `terraform/waf.tf` and `docs/security/waf-validation-plan.md` are in the reviewed `main` snapshot. | **Documented in main; live verification pending.** Terraform configuration and a validation plan do not prove that WAF is deployed or that its rules have passed live tests. WAF alone does not establish secure coding or transmission encryption. |
| Encryption and protection of stored data | GDPR Article 32; HIPAA §164.312(a)(2)(iv), where applicable; PCI DSS Requirements 3 and 4 only when in-scope account data is involved | `terraform/backend.tf` requests encryption for the Terraform S3 backend. M5 has a local Secrets Management Plan. | **Partial design evidence only.** The backend configuration does not prove that the state bucket exists or that its settings were verified. It is not evidence that application data, secrets, or network traffic are encrypted in a deployed environment. |
| Application authentication and transmission security | GDPR Articles 25 and 32; HIPAA §164.312(a), (d), and (e); PCI DSS Requirements 4, 7, and 8, where applicable | An API Gateway architecture decision is in the reviewed `main` snapshot. | **Architecture evidence only.** A design decision does not prove that Cognito, API authorization, TLS settings, or application authentication have been implemented and tested. |
| Vulnerability management and secure software changes | GDPR Article 32; HIPAA §164.308(a)(1)(ii)(A)-(B); PCI DSS Requirements 6 and 11, where applicable | The M5 CI workflow is in PR #9. This branch moves the deployment draft outside `.github/workflows/` and adds a default-disabled deployment-role draft. The worker scan report covers a specific M4 snapshot. | **PR and local evidence only.** GitHub Actions checks were triggered for the initial PR revision. Check the latest PR commit's results after these corrections are pushed before claiming a pass. Local Gitleaks scans found no leaks. DAST and ECR image scanning were not verified; the inspected M5 workspace had no `src/api` or OpenAPI specification, so DAST was not run. Worker tests passed 11/11 only with a test-only mock in a disposable copy, not on the M4 branch. |
| Configuration monitoring and audit evidence | GDPR Article 32; HIPAA §164.312(b); PCI DSS Requirement 10, where applicable | M1's AWS Config Terraform, conformance-pack template, and control inventory were merged into main by PR #7. The merged matrix reports local validation and a Terraform plan, but no resources were applied; the recorder, conformance pack, and live evaluations remain pending. | **Definitions are in main; live deployment and evaluation are pending.** PR #7 is merged, but no live AWS Config evaluation is evidenced. AWS Config rule evaluations are not a substitute for audit-event logging or a complete security review. No live `COMPLIANT` result is claimed. |
| Backup, recovery, and integrity | GDPR Article 32; HIPAA §164.308(a)(7) and §164.312(c)(1), where applicable | No live backup, restore, or recovery-test evidence was reviewed for this crosswalk. | **Not evidenced.** Terraform configuration or a planned backup rule alone would not demonstrate that recovery works; a restore test and retained evidence are needed. |
| Secrets lifecycle and incident response | GDPR Articles 32, 33, and 34; HIPAA §164.308(a)(6); PCI DSS Requirement 12.10, where applicable | M5's Secrets Management Plan is a local draft. No completed secret-rotation or incident-response test was reviewed. | **Local M5 draft / not operationally verified.** The plan does not prove that Secrets Manager, rotation, audit monitoring, or incident procedures have been deployed and tested. |

## Related project artifacts

M1's `compliance/compliance-matrix.md` and `compliance/conformance-pack.yaml`
were merged into `main` by PR #7. Those artifacts inventory selected AWS Config
rules and are distinct from this framework crosswalk. Their existence does not
establish deployment or live evaluations; recheck current AWS evidence before
final reporting.

M5's current local drafts are:

- `.github/workflows/ci-security.yml`
- `docs/security/deferred-workflows/deploy-apps.yml.disabled` (inert
  reference outside `.github/workflows/`; not executed)
- `terraform/github_deploy_role.tf` (optional role draft; disabled by default,
  locally validated only, not applied)
- `.github/pull_request_template.md`
- `docs/architecture/cicd-pipeline.md`
- `docs/security/secrets-management-plan.md`
- `docs/security/scan-reports/worker-pr8-snapshot.md`

These local files are not evidence of a successful GitHub Actions run or an
AWS deployment.

## Evidence required before making compliance claims

For each applicable control, collect and review dated evidence from the
deployed environment, such as approved IAM policies, configuration and
encryption settings, access and audit logs, scan results, test results, backup
restore results, and incident-response records. Record the assessed scope,
owner, resource, result, evidence date, and remediation.

Do not label a framework, system, or control **compliant** based only on a
Terraform file, a plan, a local scan, or an AWS Config rule definition. An AWS
Config `COMPLIANT` result applies only to that rule evaluation and resource; it
does not certify the application or the project against GDPR, HIPAA, or PCI
DSS.
