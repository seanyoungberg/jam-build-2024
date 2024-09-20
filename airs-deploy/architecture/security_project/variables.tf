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
variable "ssh_key_name" {
  description = "Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes"
  type        = string
}

### VPC
variable "vpcs" {
  description = <<-EOF
  A map defining VPCs with security groups and subnets.

  Following properties are available:
  - `name`: VPC name
  - `cidr`: CIDR for VPC
  - `nacls`: map of network ACLs
  - `security_groups`: map of security groups
  - `subnets`: map of subnets with properties:
     - `az`: availability zone
     - `set`: internal identifier referenced by main.tf
     - `nacl`: key of NACL (can be null)
  - `routes`: map of routes with properties:
     - `vpc_subnet` - built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
     - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
     - `next_hop_type` - internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint

  Example:
  ```
  vpcs = {
    example_vpc = {
      name = "example-spoke-vpc"
      cidr = "10.104.0.0/16"
      nacls = {
        trusted_path_monitoring = {
          name               = "trusted-path-monitoring"
          rules = {
            allow_inbound = {
              rule_number = 300
              egress      = false
              protocol    = "-1"
              rule_action = "allow"
              cidr_block  = "0.0.0.0/0"
              from_port   = null
              to_port     = null
            }
          }
        }
      }
      security_groups = {
        example_vm = {
          name = "example_vm"
          rules = {
            all_outbound = {
              description = "Permit All traffic outbound"
              type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
              cidr_blocks = ["0.0.0.0/0"]
            }
          }
        }
      }
      subnets = {
        "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm", nacl = null }
        "10.104.128.0/24" = { az = "eu-central-1b", set = "vm", nacl = null }
      }
      routes = {
        vm_default = {
          vpc_subnet    = "app1_vpc-app1_vm"
          to_cidr       = "0.0.0.0/0"
          next_hop_key  = "app1"
          next_hop_type = "transit_gateway_attachment"
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name = string
    cidr = string
    nacls = map(object({
      name = string
      rules = map(object({
        rule_number = number
        egress      = bool
        protocol    = string
        rule_action = string
        cidr_block  = string
        from_port   = string
        to_port     = string
      }))
    }))
    security_groups = any
    subnets = map(object({
      az   = string
      set  = string
      nacl = string
    }))
    routes = map(object({
      vpc_subnet    = string
      to_cidr       = string
      next_hop_key  = string
      next_hop_type = string
    }))
  }))
}

### TRANSIT GATEWAY
variable "tgw" {
  description = <<-EOF
  A object defining Transit Gateway.

  Following properties are available:
  - `create`: set to false, if existing TGW needs to be reused
  - `id`:  id of existing TGW or null
  - `name`: name of TGW to create or use
  - `asn`: ASN number
  - `route_tables`: map of route tables
  - `attachments`: map of TGW attachments

  Example:
  ```
  tgw = {
    create = true
    id     = null
    name   = "tgw"
    asn    = "64512"
    route_tables = {
      "from_security_vpc" = {
        create = true
        name   = "from_security"
      }
    }
    attachments = {
      security = {
        name                = "vmseries"
        vpc_subnet          = "security_vpc-tgw_attach"
        route_table         = "from_security_vpc"
        propagate_routes_to = "from_spoke_vpc"
      }
    }
  }
  ```
  EOF
  default     = null
  type = object({
    create = bool
    id     = string
    name   = string
    asn    = string
    route_tables = map(object({
      create = bool
      name   = string
    }))
    attachments = map(object({
      name                = string
      vpc_subnet          = string
      route_table         = string
      propagate_routes_to = string
    }))
  })
}

### NAT GATEWAY
variable "natgws" {
  description = <<-EOF
  A map defining NAT Gateways.

  Following properties are available:
  - `name`: name of NAT Gateway
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character

  Example:
  ```
  natgws = {
    security_nat_gw = {
      name       = "natgw"
      vpc_subnet = "security_vpc-natgw"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name       = string
    vpc_subnet = string
  }))
}

### GATEWAY LOADBALANCER
variable "gwlbs" {
  description = <<-EOF
  A map defining Gateway Load Balancers.

  Following properties are available:
  - `name`: name of the GWLB
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character

  Example:
  ```
  gwlbs = {
    security_gwlb = {
      name                             = "security-gwlb"
      vpc_subnet                       = "security_vpc-gwlb"
      enable_cross_zone_load_balancing = true
      health_check_port                = 443
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name                             = string
    vpc_subnet                       = string
    enable_cross_zone_load_balancing = bool
    health_check_port                = number
  }))
}
variable "gwlb_endpoints" {
  description = <<-EOF
  A map defining GWLB endpoints.

  Following properties are available:
  - `name`: name of the GWLB endpoint
  - `gwlb`: key of GWLB
  - `vpc`: key of VPC
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic
  - `to_vpc_subnets`: subnets to which traffic from IGW is routed to the GWLB endpoint

  Example:
  ```
  gwlb_endpoints = {
    security_gwlb_eastwest = {
      name            = "eastwest-gwlb-endpoint"
      gwlb            = "security_gwlb"
      vpc             = "security_vpc"
      vpc_subnet      = "security_vpc-gwlbe_eastwest"
      act_as_next_hop = false
      to_vpc_subnets  = null
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name            = string
    gwlb            = string
    vpc             = string
    vpc_subnet      = string
    act_as_next_hop = bool
    to_vpc_subnets  = string
  }))
}

### VM-SERIES
variable "vmseries_asgs" {
  description = <<-EOF
  A map defining Autoscaling Groups with VM-Series instances.

  Following properties are available:
  - `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama
  - `panos_version`: PAN-OS version used for VM-Series
  - `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series
  - `vpc`: key of VPC
  - `gwlb`: key of GWLB
  - `interfaces`: configuration of network interfaces for VM-Series used by Lamdba while provisioning new VM-Series in autoscaling group
  - `asg`: the number of Amazon EC2 instances that should be running in the group (desired, minimum, maximum)
  - `scaling_plan`: scaling plan with attributes
    - `enabled`: `true` if automatic dynamic scaling policy should be created
    - `metric_name`: name of the metric used in dynamic scaling policy
    - `estimated_instance_warmup`: estimated time, in seconds, until a newly launched instance can contribute to the CloudWatch metrics
    - `target_value`: target value for the metric used in dynamic scaling policy
    - `statistic`: statistic of the metric. Valid values: Average, Maximum, Minimum, SampleCount, Sum
    - `cloudwatch_namespace`: name of CloudWatch namespace, where metrics are available (it should be the same as namespace configured in VM-Series plugin in PAN-OS)
    - `tags`: tags configured for dynamic scaling policy
  - `vmseries_ami_id`: ami to use to launch instances
  - `instance_refresh`: instance refresh for ASG defined by several attributes (please README for module `asg` for more details)

  Example:
  ```
  vmseries_asgs = {
    main_asg = {
      bootstrap_options = {
        mgmt-interface-swap                   = "enable"
        plugin-op-commands                    = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
        panorama-server                       = ""
        vm-auth-key                           = ""
        dgname                                = ""
        tplname                               = ""
        dhcp-send-hostname                    = "yes"
        dhcp-send-client-id                   = "yes"
        dhcp-accept-server-hostname           = "yes"
        dhcp-accept-server-domain             = "yes"
        authcodes                             = ""
        vm-series-auto-registration-pin-id    = ""
        vm-series-auto-registration-pin-value = ""
      }

      panos_version         = "10.2.3"
      vmseries_product_code = "6njl1pau431dv1qxipg63mvah"
      ebs_kms_id            = "alias/aws/ebs"

      vpc               = "security_vpc"
      gwlb              = "security_gwlb"

      interfaces = {
        private = {
          device_index   = 0
          security_group = "vmseries_private"
          subnet = {
            "privatea" = "eu-central-1a",
            "privateb" = "eu-central-1b"
          }
          create_public_ip  = false
          source_dest_check = false
        }
        mgmt = {
          device_index   = 1
          security_group = "vmseries_mgmt"
          subnet = {
            "mgmta" = "eu-central-1a",
            "mgmtb" = "eu-central-1b"
          }
          create_public_ip  = true
          source_dest_check = true
        }
        public = {
          device_index   = 2
          security_group = "vmseries_public"
          subnet = {
            "publica" = "eu-central-1a",
            "publicb" = "eu-central-1b"
          }
          create_public_ip  = false
          source_dest_check = false
        }
      }


      asg = {
        desired_cap                     = 0
        min_size                        = 0
        max_size                        = 4
        instance_type                   = m5.xlarge
        health_check_grace_period       = 300
        lambda_execute_pip_install_once = true
      }

      scaling_plan = {
        enabled                   = true
        metric_name               = "panSessionActive"
        estimated_instance_warmup = 900
        target_value              = 75
        statistic                 = "Average"
        cloudwatch_namespace      = "asg-vmseries"
        tags = {
          ManagedBy = "terraform"
        }
      }

      launch_template_version = "1"

      instance_refresh = {
        strategy = "Rolling"
        preferences = {
          checkpoint_delay             = 3600
          checkpoint_percentages       = [50, 100]
          instance_warmup              = 1200
          min_healthy_percentage       = 50
          skip_matching                = false
          auto_rollback                = false
          scale_in_protected_instances = "Ignore"
          standby_instances            = "Ignore"
        }
        triggers = []
      }

      delicense = {
        enabled = true
        ssm_param_name = "example_param_store_delicense"
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    bootstrap_options = object({
      mgmt-interface-swap                   = string
      plugin-op-commands                    = string
      panorama-server                       = string
      vm-auth-key                           = string
      dgname                                = string
      tplname                               = string
      dhcp-send-hostname                    = string
      dhcp-send-client-id                   = string
      dhcp-accept-server-hostname           = string
      dhcp-accept-server-domain             = string
      authcodes                             = string
      vm-series-auto-registration-pin-id    = string
      vm-series-auto-registration-pin-value = string
    })

    panos_version         = string
    vmseries_product_code = string
    #ebs_kms_id    = string

    vpc  = string
    gwlb = string

    interfaces = map(object({
      device_index      = number
      security_group    = string
      subnet            = map(string)
      create_public_ip  = bool
      source_dest_check = bool
    }))

    asg = object({
      desired_cap                     = number
      min_size                        = number
      max_size                        = number
      instance_type                   = string
      health_check_grace_period       = number
      lambda_execute_pip_install_once = bool
    })

    scaling_plan = object({
      enabled                   = bool
      metric_name               = string
      estimated_instance_warmup = number
      target_value              = number
      statistic                 = string
      cloudwatch_namespace      = string
      tags                      = map(string)
    })

    vmseries_ami_id = string

    instance_refresh = object({
      strategy = string
      preferences = object({
        checkpoint_delay             = number
        checkpoint_percentages       = list(number)
        instance_warmup              = number
        min_healthy_percentage       = number
        skip_matching                = bool
        auto_rollback                = bool
        scale_in_protected_instances = string
        standby_instances            = string
      })
      triggers = list(string)
    })

    delicense = object({
      enabled        = bool
      ssm_param_name = string
    })
  }))
}

### PANORAMA
variable "panorama_attachment" {
  description = <<-EOF
  A object defining TGW attachment and CIDR for Panorama.

  Following properties are available:
  - `transit_gateway_attachment_id`: ID of attachment for Panorama
  - `vpc_cidr`: CIDR of the VPC, where Panorama is deployed

  Example:
  ```
  panorama = {
    transit_gateway_attachment_id = "tgw-attach-123456789"
    vpc_cidr                      = "10.255.0.0/24"
  }
  ```
  EOF
  default     = null
  type = object({
    transit_gateway_attachment_id = string
    vpc_cidr                      = string
  })
}

### SPOKE VMS
variable "spoke_vms" {
  description = <<-EOF
  A map defining VMs in spoke VPCs.

  Following properties are available:
  - `az`: name of the Availability Zone
  - `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `security_group`: security group assigned to ENI used by VM
  - `type`: EC2 type VM

  Example:
  ```
  spoke_vms = {
    "app1_vm01" = {
      az             = "eu-central-1a"
      vpc            = "app1_vpc"
      vpc_subnet     = "app1_vpc-app1_vm"
      security_group = "app1_vm"
      type           = "t2.micro"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    az             = string
    vpc            = string
    vpc_subnet     = string
    security_group = string
    type           = string
  }))
}

### SPOKE LOADBALANCERS
variable "spoke_lbs" {
  description = <<-EOF
  A map defining Network Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `vms`: keys of spoke VMs

  Example:
  ```
  spoke_lbs = {
    "app1-nlb" = {
      vpc_subnet = "app1_vpc-app1_lb"
      vms        = ["app1_vm01", "app1_vm02"]
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    vpc_subnet = string
    vms        = list(string)
  }))
}

variable "vmseries" {
  description = <<-EOF
  A map defining VM-Series instances
  Following properties are available:
  - `instances`: map of VM-Series instances
  - `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama
  - `panos_version`: PAN-OS version used for VM-Series
  - `vmseries_ami_id`: ami to use to launch instances
  - `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series
  - `vpc`: key of VPC
  Example:
  ```
  vmseries = {
    vmseries = {
      instances = {
        "01" = { az = "eu-central-1a" }
      }
      bootstrap_options = {
        mgmt-interface-swap                   = "enable"
        plugin-op-commands                    = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
        vm-auth-key                           = ""
        dgname                                = ""
        tplname                               = ""
        dhcp-send-hostname                    = "yes"
        dhcp-send-client-id                   = "yes"
        dhcp-accept-server-hostname           = "yes"
        dhcp-accept-server-domain             = "yes"
        authcodes                             = ""
        vm-series-auto-registration-pin-id    = ""
        vm-series-auto-registration-pin-value = ""

      }
      panos_version         = "10.2.3"
      vmseries_product_code = "6njl1pau431dv1qxipg63mvah"
      ebs_kms_id            = "alias/aws/ebs"

      # Value of `vpc` must match key of objects stored in `vpcs`
      vpc = "security_vpc"

      interfaces = {
        mgmt = {
          device_index      = 1
          private_ip        = "10.100.0.4"
          security_group    = "vmseries_mgmt"
          vpc_subnet        = "security_vpc-mgmt"
          create_public_ip  = true
          source_dest_check = true
          eip_allocation_id = null
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    instances = map(object({
      az = string
    }))

    bootstrap_options = object({
      mgmt-interface-swap                   = string
      panorama-server                       = string
      plugin-op-commands                    = string
      vm-auth-key                           = string
      dgname                                = string
      tplname                               = string
      dhcp-send-hostname                    = string
      dhcp-send-client-id                   = string
      dhcp-accept-server-hostname           = string
      dhcp-accept-server-domain             = string
      authcodes                             = string
      vm-series-auto-registration-pin-id    = string
      vm-series-auto-registration-pin-value = string
    })

    panos_version = string
    #ebs_kms_id    = string
    vmseries_ami_id       = string
    vmseries_product_code = string

    vpc = string

    interfaces = map(object({
      device_index      = number
      private_ip        = map(string)
      security_group    = string
      vpc_subnet        = string
      create_public_ip  = bool
      source_dest_check = bool
      eip_allocation_id = map(string)
    }))
  }))
}
