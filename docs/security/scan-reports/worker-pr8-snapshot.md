# Preliminary Security Scan Report — Worker Snapshot

## Scope and status

This is a local, preliminary report for the worker snapshot observed on
`origin/container/m4-worker-base` at commit `64c320f`. It covers the worker
source and declared Python requirements in that snapshot; it is not a scan of
the entire repository and is not a GitHub Actions result.

The report records summary results only. Raw logs and secret values are not
included.

## Results

| Check | Tool/version | Result |
|---|---|---|
| Python static analysis | Bandit 1.9.4 | Passed: 129 lines scanned; no issues identified. |
| Dependency vulnerability audit | pip-audit 2.10.1 | Passed: no known vulnerabilities found in the declared worker requirements at scan time. |
| Unit tests, unmodified snapshot | pytest 9.2.0 | Initial run: 10 passed, 1 failed when Boto3 read the local AWS login profile and failed during credential-provider lookup. |
| Unit tests, unmodified snapshot with AWS auth sources disabled | pytest 9.2.0 | Passed: all 11 tests on Python 3.14.4 with AWS profile/credential sources removed and EC2 metadata disabled; no AWS credentials were used. |
| Unit tests, temporary test-only mock | pytest 9.2.0 | 11 passed after mocking Boto3 client/resource creation around the new `Worker()` instance. This change was made only in a disposable `/tmp` copy; it was not applied to the M4 branch. |
| Secret scan | Local Gitleaks CLI (version metadata unavailable) | Passed: no leaks found in the non-ignored working-tree files or Git history (17 commits scanned). The GitHub Actions workflow has not yet run. |

## Test environment and notes

- Gitleaks scanned a temporary copy of the current non-ignored working tree, including untracked M5 files, and separately scanned Git history. Results were redacted; the local scan is not a GitHub Actions result.

- Local Python version: 3.14.4. The repository CI is configured to use Python 3.12.
- The initial failure occurred before any AWS API request. Boto3 attempted
  to resolve credentials using the local AWS login provider and reported its
  missing optional `botocore[crt]` dependency. The unmodified tests then passed
  when AWS profile/credential sources were removed and instance metadata was
  disabled; no code change was needed.
- After the tests passed in the temporary copy, the X-Ray SDK logged a failed
  attempt to reach a local sampling daemon at `127.0.0.1:2000`. This was a
  localhost connection attempt, not an AWS connection, and did not fail the
  test run.
- The temporary test edit was discarded when the temporary directory was
  removed. No M4 files or AWS resources were changed.

## Limitations

These results do not establish that the full application or infrastructure is
secure. They do not include Gitleaks, an ECR image scan, OWASP ZAP/DAST, a
Terraform plan, deployment testing, or AWS runtime verification. Dependency
audit results reflect the advisory data available when the scan ran.
