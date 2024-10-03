terraform {
  required_version = ">= 1.3, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6.0"
    }
  }
  backend "s3" {
    encrypt = true
  }
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = var.infra_state_key
    region = var.aws_region
  }
}

provider "kubectl" {
  host                   = data.terraform_remote_state.infrastructure.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infrastructure.outputs.eks_cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.infrastructure.outputs.eks_cluster_name]
  }
}