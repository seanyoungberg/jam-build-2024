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
    bucket         = var.s3_bucket  # Replace this with the actual S3 bucket name
    key            = "terraform/state"            # Path inside the bucket to store the state file
    region         = var.region                   # AWS region
    encrypt        = true                         # Enable server-side encryption of the state file
    dynamodb_table = "terraform-lock"             # Optional: To avoid race conditions
  }
}

provider "aws" {
  region  = var.region
}