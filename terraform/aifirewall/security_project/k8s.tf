provider "kubectl" {
  host                   = module.eks_al2023.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_al2023.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_al2023.cluster_name]
  }
}

locals {
  yaml_documents = split("---", file("${path.module}/deploy.yaml"))
}

resource "kubectl_manifest" "app_manifests" {
  for_each  = { for idx, doc in local.yaml_documents : idx => doc if trimspace(doc) != "" }
  yaml_body = each.value
}
