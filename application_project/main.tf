data "aws_subnets" "app_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}app1_lb*"]
  }
}

locals {
  # Pass in LB subnets for the Public ELB service
  app1_lb_subnet_ids_string = join(",", data.aws_subnets.app_subnets.ids)

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

resource "helm_release" "ai_runtime_security" {
  name       = "ai-runtime-security"
  chart      = "${path.module}/airs_cni_helm/Chart.yaml"
  namespace  = "kube-system"
  
  wait       = true
  timeout    = 300  # 10 minutes, adjust as needed

  # You can set values from your Chart.yaml file here
  set {
    name  = "endpoints1"
    value = "10.111.0.75"
  }

  set {
    name  = "endpoints1zone"
    value = "us-east-1a"
  }

  set {
    name  = "endpoints2"
    value = "10.111.1.76"
  }

  set {
    name  = "endpoints2zone"
    value = "us-east-1b"
  }
}