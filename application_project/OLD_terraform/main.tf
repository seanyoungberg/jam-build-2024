data "aws_subnets" "app_subnets" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}app1_lb*"]
  }
}

data "aws_iam_role" "bedrock_role" {
  name = "${var.name_prefix}eks-pod-role"
}

locals {
  # Pass in LB subnets for the Public ELB service
  app1_lb_subnet_ids_string = join(",", data.aws_subnets.app_subnets.ids)

  # Read and template the file
  service_accounts = templatefile("${path.module}/k8s_manifests/service_accounts.yaml", {
    role_arn = data.aws_iam_role.bedrock_role.arn
  })

  # Read and template the file
  ai_app_ca = templatefile("${path.module}/k8s_manifests/ai_app_ca.yaml", {
    trust_ca_root = file("${path.module}/ca/Root-CA.pem")
    forward_trust_ca_ecdsa = file("${path.module}/ca/Forward-Trust-CA-ECDSA.pem")
    forward_trust_ca = file("${path.module}/ca/Forward-Trust-CA.pem")
  })

  # Read and template the file
  ai_app = templatefile("${path.module}/k8s_manifests/ai_app.yaml", {
    lb_subnet_ids = local.app1_lb_subnet_ids_string
  })

  # Split the templated YAML into separate documents
  namespaces = [for doc in split("---", file("${path.module}/k8s_manifests/namespaces.yaml")) : trimspace(doc) if trimspace(doc) != ""]
  ai_app_yaml = [for doc in split("---", local.ai_app) : trimspace(doc) if trimspace(doc) != ""]
  ai_app_netshoot_yaml = [for doc in split("---", file("${path.module}/k8s_manifests/netshoot.yaml")) : trimspace(doc) if trimspace(doc) != ""]
  ai_app_aws_cli_yaml = [for doc in split("---", file("${path.module}/k8s_manifests/aws_cli.yaml")) : trimspace(doc) if trimspace(doc) != ""]
}

resource "kubectl_manifest" "service_accounts" {
  yaml_body = local.service_accounts
}

resource "kubectl_manifest" "namespaces" {
  for_each  = { for idx, doc in local.namespaces : idx => doc if trimspace(doc) != "" }
  yaml_body = each.value
  depends_on = [kubectl_manifest.service_accounts]
}

resource "kubectl_manifest" "ai_app_ca" {
  yaml_body = local.ai_app_ca
  depends_on = [kubectl_manifest.namespaces]
}

resource "kubectl_manifest" "ai_app" {
  for_each  = { for idx, doc in local.ai_app_yaml : idx => doc if trimspace(doc) != "" }
  yaml_body = each.value
  depends_on = [kubectl_manifest.ai_app_ca]
}

resource "kubectl_manifest" "ai_app_netshoot" {
  for_each  = { for idx, doc in local.ai_app_netshoot_yaml : idx => doc if trimspace(doc) != "" }
  yaml_body = each.value
  depends_on = [kubectl_manifest.ai_app_ca]
}

resource "kubectl_manifest" "ai_app_aws_cli" {
  for_each  = { for idx, doc in local.ai_app_aws_cli_yaml : idx => doc if trimspace(doc) != "" }
  yaml_body = each.value
  depends_on = [kubectl_manifest.ai_app_ca]
}