locals {
  # Pass in LB subnets for the Public ELB service
  app1_lb_subnet_ids_string = join(",", [for subnet in data.terraform_remote_state.infrastructure.outputs.app1_lb_subnet_ids : subnet.id])

  # Read and template the file
  templated_yaml = templatefile("${path.module}/k8s_manifests/deploy.yaml", {
    lb_subnet_ids = local.app1_lb_subnet_ids_string
  })

  # Split the templated YAML into separate documents
  yaml_documents = [for doc in split("---", local.templated_yaml) : trimspace(doc) if trimspace(doc) != ""]
}

resource "kubectl_manifest" "app_manifests" {
  for_each  = { for idx, doc in local.yaml_documents : idx => doc if trimspace(doc) != "" }
  yaml_body = each.value
}
