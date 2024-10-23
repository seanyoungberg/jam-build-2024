terraform {
  required_version = ">= 1.2.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.66.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
  }

  backend "s3" {
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "eks_cluster" {
  name = "${var.name_prefix}eks"
  depends_on = [module.eks_al2023]
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = "${var.name_prefix}eks"
  depends_on = [module.eks_al2023]
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_cluster.token
}
