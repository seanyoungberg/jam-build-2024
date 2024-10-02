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
  backend "s3" {
    encrypt        = true
  }
}

provider "aws" {
  region  = var.region
}
