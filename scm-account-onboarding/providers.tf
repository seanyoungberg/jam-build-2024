terraform {
  required_version = ">= 1.3, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
}

provider "aws" {
  alias   = "onboarding"
  profile = "pso-cloud-gsa-lab-OKTA_SSO-sso_admin"
  region  = var.customer_aws_region
}
