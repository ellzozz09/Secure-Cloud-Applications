## Summary
<!-- What does this PR change, and why? -->

## Related task and dependencies
<!-- Link the task or PRs; note coordination needed with M1–M4. -->

## Validation
- [ ] `pytest` (when Python tests are present)
- [ ] Bandit (when Python source is present)
- [ ] `pip-audit` (when Python requirements are present)
- [ ] Gitleaks
- [ ] Terraform `fmt` and `validate` (when Terraform files are changed)
- [ ] Terraform `plan` reviewed when applicable and supported by the M1-approved CI setup

## Security and infrastructure
- [ ] No credentials, tokens, or plaintext secrets were added.
- [ ] No `terraform apply` was run by CI.
- [ ] AWS impact, region, and cost were reviewed where applicable.
- [ ] Required cross-member coordination is complete.
