## Setup application VPC routing and others

module "appvpc_setup" {
  source = "../../modules/appvpc_setup"

  for_each = var.vpcs

  region               = var.region
  name_prefix          = var.name_prefix
  global_tags          = var.global_tags
  vpc_endpoint_service = var.vpc_endpoint_service
  tgw                  = var.tgw
  vpc_id               = each.value.id
  gwlb_endpoints       = each.value.gwlb_endpoints
}
