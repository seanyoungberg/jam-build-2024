### GENERAL
region      = "us-west-2" # TODO: update here
name_prefix = "example-"  # TODO: update here

global_tags = {
  ManagedBy = "terraform"
  Product   = "Palo Alto Networks VM-Series NGFW"
}

vpc_endpoint_service = {
  service_name = "com.amazonaws.vpce.us-west-2.vpce-svc-02d901382cf6842d2" # TODO: update here
  tag_name     = null                                                      # NOTE: Used by PANW service.
  tag_value    = null                                                      # NOTE: Used by PANW service.
}

tgw = {
  id        = "tgw-04af2d180a598ea1e" #TODO: update here if you know the Transit Gateway ID
  tag_name  = null                    # NOTE: Used by PANW service.
  tag_value = null                    # NOTE: Used by PANW service.
}

vpcs = {
  app1_vpc = {
    id = "vpc-01594030b6f33093c"
    gwlb_endpoints = {
      gwlbe_1 = {
        subnet_cidr    = "10.1.3.0/24"
        subnet_id_for_tgw_attachment = "subnet-04942fbec8edf14f5"
        k8s_subnet_ids = ["subnet-04942fbec8edf14f5"]
        vm_subnet_ids  = ["subnet-04e7a90210aef73a5"]
        az             = "us-west-2a"
      }
      gwlbe_2 = {
        subnet_cidr    = "10.1.4.0/24"
        subnet_id_for_tgw_attachment = ""
        k8s_subnet_ids = []
        vm_subnet_ids  = []
        az             = "us-west-2c"
      }
    }
  }
}
