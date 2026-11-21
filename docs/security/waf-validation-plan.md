# AWS WAF Validation Plan

## 1. Purpose

This document defines the validation approach for the Regional AWS WAF Web ACL protecting the Secure Cloud Applications API.

The objective is to verify that the configured WAF rules help protect the API against common web attacks while allowing legitimate application traffic.

**Current status:** The Web ACL Terraform definition has been merged. Deployment, API Gateway association, and runtime testing are pending.

## 2. Scope

The current WAF configuration includes:

| Rule | Purpose |
|---|---|
| AWSManagedCommonRules | Protect against common web application attack patterns |
| AWSManagedKnownBadInputs | Detect known malicious input patterns |
| AWSManagedSQLiProtection | Detect SQL injection patterns |
| IPRateLimit | Block IP addresses exceeding the configured request threshold |

The Web ACL uses Regional scope and is intended to protect the API Gateway REST API stage.

## 3. Prerequisites

Before executing the tests:

- Deploy the Terraform infrastructure in the approved AWS environment.
- Confirm that the Regional Web ACL has been created successfully.
- Associate the Web ACL with the API Gateway stage.
- Confirm that the API endpoint is reachable.
- Confirm that the API's authentication and authorization requirements are working.
- Ensure that WAF CloudWatch metrics are available.

WAF logging must be configured separately before log-based validation can be performed.

## 4. Validation Test Cases

### Test 1: Legitimate API Requests

**Objective:** Verify that normal application requests are not blocked by WAF.

**Procedure:**
1. Send a valid request to an API endpoint.
2. Use valid authentication credentials when required.
3. Repeat with representative valid request bodies and parameters.
4. Inspect the API response and WAF metrics.

**Expected result:** Legitimate requests should reach the API and receive the expected application response.

### Test 2: AWS Managed Common Rule Set

**Objective:** Verify that the Common Rule Set is active.

**Procedure:**
1. Send normal requests to establish a baseline.
2. In a controlled test environment, submit safe test inputs that match documented managed-rule test patterns.
3. Inspect the resulting HTTP responses and WAF metrics.

**Expected result:** Requests matching blocking rules should be blocked by WAF, while legitimate requests should continue to work.

### Test 3: Known Bad Inputs Protection

**Objective:** Verify that the Known Bad Inputs managed rule group is active.

**Procedure:**
1. Use controlled, non-destructive test inputs corresponding to documented known-bad patterns.
2. Send the requests to the protected API.
3. Inspect the responses and WAF metrics.

**Expected result:** Requests matching blocking rules should be blocked.

### Test 4: SQL Injection Protection

**Objective:** Verify that the SQL Injection managed rule group is active.

**Procedure:**
1. Use harmless SQL injection test strings in a controlled test environment.
2. Submit them through appropriate API parameters or request fields.
3. Inspect the responses and WAF metrics.

**Expected result:** Requests matching the managed SQL injection rules should be blocked.

**Safety note:** These tests must not attempt to access, modify, or delete real application data.

### Test 5: IP-Based Rate Limiting

**Objective:** Verify the configured rate-based rule.

**Configuration:**
- Aggregation: Source IP address
- Threshold: 2,000 requests
- Evaluation window: 300 seconds
- Action: Block

**Procedure:**
1. Use a controlled test client and a non-production environment.
2. Generate requests from one source IP at a controlled rate.
3. Monitor the response codes and WAF metrics.
4. Stop the test if unexpected load or cost is observed.

**Expected result:** Once the configured rate-based rule identifies an IP exceeding its threshold, subsequent requests from that IP should be blocked according to WAF evaluation.

**Important:** Rate-based rules are evaluated over a rolling time window and should not be treated as an exact request counter or guaranteed instantaneous cutoff.

### Test 6: WAF Metrics and Monitoring

**Objective:** Verify that WAF metrics are available for monitoring.

**Procedure:**
1. Open the AWS WAF console.
2. Navigate to the deployed Web ACL.
3. Inspect its CloudWatch metrics.
4. Generate legitimate and controlled test traffic.
5. Observe whether the relevant metrics change.

**Expected result:** The Web ACL and its rules should publish the configured CloudWatch metrics.

### Test 7: False-Positive Validation

**Objective:** Ensure that legitimate application requests are not incorrectly blocked.

**Procedure:**
1. Execute representative application workflows.
2. Test valid request bodies, query parameters, and authentication flows.
3. Inspect any blocked requests.
4. Identify which managed rule caused the block.
5. Review the rule behavior before making any exclusions or overrides.

**Expected result:** Normal application functionality should remain available without weakening the intended security protections.

## 5. Monitoring and Evidence

For each test, record:

- Test case ID and name.
- Date and time.
- Test environment.
- Request type.
- HTTP response status.
- Relevant WAF rule or metric.
- Expected result.
- Actual result.
- Pass/Fail status.
- Notes and corrective actions.

Capture relevant CloudWatch metric screenshots or WAF log evidence where available.

## 6. Acceptance Criteria

The WAF validation can be considered successful when:

- The Web ACL is associated with the intended API Gateway stage.
- Legitimate application requests are allowed.
- The configured managed rule groups operate as expected.
- SQL injection and known-bad-input test cases are handled as expected.
- IP-based rate limiting is verified in a controlled environment.
- CloudWatch metrics are available.
- False positives have been investigated and addressed.

## 7. Current Limitations and Pending Integration

The following items are not yet confirmed as implemented:

- API Gateway stage association, pending Member 3's API Gateway stage ARN.
- Deployment of the Web ACL to AWS.
- WAF logging configuration.
- Runtime validation and evidence collection.
- Final false-positive review.

These items must be completed before declaring the WAF fully deployed and validated.

## 8. Ownership

**Member 1 — Security Architecture, IAM, WAF & Compliance**

Responsible for:
- Defining and maintaining the WAF Web ACL.
- Coordinating the API Gateway association with Member 3.
- Preparing and executing WAF security validation.
- Reviewing WAF metrics and security behavior.
- Documenting validation results and corrective actions.
