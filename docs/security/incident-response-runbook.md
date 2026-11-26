# Incident Response Runbook

## Status

Proposed guide for the student project; it has not been exercised. Confirm
the incident lead, private reporting channel, and response authority with the
team. This document does not establish that AWS resources or audit logging
are deployed, or decide whether a legal notification is required.

## Response

1. **Report:** Notify the designated lead privately. Never put credentials,
   tokens, secret values, or sensitive user data in chat, PRs, or reports.
2. **Triage:** Record the UTC discovery time, affected service or workflow,
   relevant commit/PR/run IDs, what is known, and what remains uncertain.
   Do not assume the project handles regulated data.
3. **Contain:** Ask the authorized credential owner to revoke or rotate an
   exposed secret. Removing it from the latest commit does not make it safe.
   The authorized cloud owner handles AWS containment; M5 must not request or
   use AWS credentials.
4. **Preserve evidence:** Keep approved, access-restricted evidence and redact
   sensitive values. Verify which audit logs are actually available; AWS Config
   evaluations are not a substitute for audit-event logs.
5. **Recover:** Fix the cause, review the change through the normal PR process,
   and verify service behavior. Under project governance, only M1 runs
   Terraform `apply` locally after reviewed PRs are merged and handles
   `destroy` after evaluation. M5 must not run either command.
6. **Close:** Record the timeline, actions, evidence references, unresolved
   risks, owners, and follow-up dates without copying secret values. Qualified
   organizational leadership decides any external or regulatory notification.

## Sanitized incident record

- Incident ID and discovery time (UTC):
- Lead and affected service/workflow:
- Sanitized description and suspected exposure window:
- Evidence links/IDs (no secret values):
- Containment and recovery actions, owners, and times:
- Follow-up owner, due date, and closure approval:

## Verification

This proposed process, team contacts, audit-log availability, and tabletop
exercise have not been verified.
