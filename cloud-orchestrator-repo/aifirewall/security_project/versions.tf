terraform {
  required_version = ">= 1.2.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.66.0"
    }
  }
  
  backend "s3" {
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
