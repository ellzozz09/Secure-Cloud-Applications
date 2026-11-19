# ADR-001: API Gateway Endpoint Type

- **Status:** Accepted
- **Decision date:** 2026-11-19
- **Decision owner:** Member 1 — Security Architecture

## 1. Context

The project uses Amazon API Gateway as the entry point to a serverless application.

The implementation plan specifies a REST API integrated with AWS Lambda, Amazon Cognito authentication, CloudWatch access logging, route throttling, and AWS WAF protection.

However, the implementation plan does not explicitly specify the API Gateway endpoint type.

## 2. Decision

We will use an API Gateway REST API with the **REGIONAL** endpoint type in `us-east-1`.

## 3. Rationale

- The application is deployed primarily within one AWS Region.
- A separate CloudFront distribution is not required by the current project architecture.
- Regional API Gateway integrates directly with a Regional AWS WAF Web ACL.
- This approach avoids unnecessary infrastructure and additional configuration complexity.
- It is appropriate for the project's cost-aware implementation strategy.

## 4. Security Implications

- Associate a Regional AWS WAF Web ACL with the API Gateway stage.
- Enable AWS Managed Common Rule Set protections.
- Enable Known Bad Inputs and SQL Injection protections.
- Configure IP-based rate limiting.
- Use Amazon Cognito authentication for protected API routes.
- Enable API Gateway access logging through CloudWatch.

## 5. Implementation Responsibilities

- **Member 1:** Define the Regional AWS WAF Web ACL and its security rules.
- **Member 3:** Configure the API Gateway REST API with `REGIONAL` endpoint type and export its stage ARN.
- **Member 1 + Member 3:** Integrate the WAF Web ACL with the API Gateway stage.

## 6. Consequences and Limitations

- The API will not automatically use CloudFront's global edge distribution.
- If the application later requires global edge delivery, CloudFront can be evaluated as a separate architectural enhancement.
- The WAF association must use the Regional scope and the correct API Gateway stage ARN.

## 7. References

- DEPI Project 5 — Complete & Feasible Team Implementation Plan.
- AWS API Gateway documentation: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-endpoint-types.html
- AWS WAF documentation: https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-associating-aws-resource.html

## 8. Integration Note

- The AWS WAF Web ACL must use `REGIONAL` scope.
- The Web ACL association will be configured after Member 3 exports the API Gateway stage ARN.
- The association will be managed using Terraform's `aws_wafv2_web_acl_association` resource.
