variable "project_name" {
  description = "Project identifier used for naming AWS resources."
  type        = string
  default     = "depi-dev"
}

variable "aws_region" {
  description = "AWS region where project resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "github_repository" {
  description = "GitHub repository allowed to authenticate through OIDC."
  type        = string
  default     = "ellzozz09/Secure-Cloud-Applications"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}