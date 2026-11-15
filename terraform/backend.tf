terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "depi-team-3-tfstate"
    key          = "project/terraform.tfstate"
    region       = "us-east-1"
    profile      = "depi-team-3"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "depi-team-3"

  default_tags {
    tags = {
      Project   = "depi-team-3"
      ManagedBy = "terraform"
    }
  }
}