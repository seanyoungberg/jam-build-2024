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

# data "aws_eks_cluster" "cluster" {
#   name = module.eks_al2023.aws_eks_cluster.this[0].name
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks_al2023.aws_eks_cluster.this[0].name
# }

# provider "kubectl" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
#   }
# }