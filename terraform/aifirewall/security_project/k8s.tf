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
  # Pass in LB subnets for the Public ELB service
  lb_subnet_ids = join(",", [
    module.subnet_sets["app1_vpc-app1_lb"].subnets["us-east-1a"].id,
    module.subnet_sets["app1_vpc-app1_lb"].subnets["us-east-1b"].id
  ])

  # Read and template the file
  templated_yaml = templatefile("${path.module}/deploy.yaml", {
    lb_subnet_ids = local.lb_subnet_ids
  })

  # Split the templated YAML into separate documents
  yaml_documents = [for doc in split("---", local.templated_yaml) : trimspace(doc) if trimspace(doc) != ""]
}

resource "kubectl_manifest" "app_manifests" {
  for_each  = { for idx, doc in local.yaml_documents : idx => doc if trimspace(doc) != "" }
  yaml_body = each.value
}
