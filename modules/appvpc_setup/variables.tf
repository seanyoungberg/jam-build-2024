### GENERAL
variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}
variable "name_prefix" {
  description = "Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.)"
  type        = string
}
variable "global_tags" {
  description = "Global tags configured for all provisioned resources"
}

variable "vpc_id" {
  description = "Application VPC ID"
  type        = string
}

#variable "natgw" {
#  description = "natgw id"
#  type        = string
#}

variable "vpc_endpoint_service" {
  description = <<-EOF
  A object defining VPC endpoint service.

  Following properties are available:
  - `service_name`:  the service name of the existing VPC endpoint service or null
  - `tag_name`: tag name of PANW created for finding out the VPC endpoint service
  - `tag_value`: the value of tag name of PANW created

  Example:
  ```
  tgw = {
    service_name = null
    tag_name     = "tag:paloaltonetworks.com-occupied"
    tag_value    = "3BYPXpUIR"
  }
  ```
  EOF
  default     = null
  type = object({
    service_name = string
    tag_name     = string
    tag_value    = string
  })
}

variable "tgw" {
  description = <<-EOF
  A object defining Transit Gateway.

  Following properties are available:
  - `id`:  id of existing TGW or null
  - `tag_name`: tag name of PANW created for finding out the tgw
  - `tag_value`: the value of tag name of PANW created

  Example:
  ```
  tgw = {
    id        = null
    tag_name  = "tag:paloaltonetworks.com-occupied"
    tag_value = "3BYPXpUIR"
  }
  ```
  EOF
  default     = null
  type = object({
    id        = string
    tag_name  = string
    tag_value = string
  })
}

variable "gwlb_endpoints" {
  description = <<-EOF
  A map defining VPCs with application groups and subnets.

  Following properties are available:
  gwlb_endpoints: map of gwlb endpoints with properties:
    - `subnet`: the CIDR for the creating GWLB endpoint
    - `k8s_subnets_ids`: list of subnet IDs which using by k8s
    - `vm_subnets_ids`: list of subnet IDs which using by App workloads
    - `az`: availability zone for the GWLB endpoint

  Example:
  ```
  gwlb_endpoints = {
    gwlbe_1 = {
      subnet_cidr    = "10.1.3.0/24"
      k8s_subnet_ids = ["subnet-04942fbec8edf14f5"]
      vm_subnet_ids  = ["subnet-04e7a90210aef73a5"]
      az             = "us-west-2a"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    subnet_cidr                  = string
    az                           = string
    subnet_id_for_tgw_attachment = string
    k8s_subnet_ids               = list(string)
    vm_subnet_ids                = list(string)
  }))
}
