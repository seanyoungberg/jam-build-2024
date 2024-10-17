### GENERAL
region      = "us-east-1"   # REPLACE-WITH customer region
name_prefix = "123456-jam-" # REPLACE-WITH prefix to be used in deployment

global_tags = {
  ManagedBy                       = "terraform"
  Application                     = "Palo Alto Networks VM-Series NGFW"
  "paloaltonetworks.com-occupied" = "NHAUdHiNg"
  "paloaltonetworks.com-trust"    = "NHAUdHiNg"
  Owner                           = "PS Team"
  RunStatus = "NOSTOP"
  NOSTOP_REASON = "Daily testing"
  NOSTOP_EXPECTED_END_DATE = "2024-12-30"
}

ssh_key_name = "shared-ps-key" # REPLACE-WITH Keypair created
user_iam_role = "arn:aws:iam::367521625516:role/sso_admin"

### VPC
vpcs = {
  # Do not use `-` in key for VPC as this character is used in concatation of VPC and subnet for module `subnet_set` in `main.tf`
  security_vpc = {
    name  = "security-vpc"
    cidr  = "10.111.0.0/23"
    nacls = {}
    security_groups = {
      vmseries_private = {
        name = "airs_private"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          geneve = {
            description = "Permit GENEVE to GWLB subnets"
            type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
            cidr_blocks = [
              "10.111.0.48/28", "10.111.1.48/28"
            ]
          }
          health_probe = {
            description = "Permit Port 443 Health Probe to GWLB subnets"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = [
              "10.111.0.48/28", "10.111.1.48/28"
            ]
          }
        }
      }
      vmseries_mgmt = {
        name = "airs_mgmt"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf
      # Value of `nacl` must match key of objects stored in `nacls`
      # REPLACE-WITH. There might be more than 2 zones, in the region. Make sure to add all the zones in the region or
      # alteast the zones in which applications are presnet.
      "10.111.0.0/28"  = { az = "us-east-1a", set = "mgmt", nacl = null }                         # REPLACE-WITH customer region's zones
      "10.111.1.0/28"  = { az = "us-east-1b", set = "mgmt", nacl = null }                         # REPLACE-WITH customer region's zones
      "10.111.0.16/28" = { az = "us-east-1a", set = "private", nacl = "trusted_path_monitoring" } # REPLACE-WITH customer region's zones
      "10.111.1.16/28" = { az = "us-east-1b", set = "private", nacl = "trusted_path_monitoring" } # REPLACE-WITH customer region's zones
      "10.111.0.32/28" = { az = "us-east-1a", set = "tgw_attach", nacl = null }                   # REPLACE-WITH customer region's zones
      "10.111.1.32/28" = { az = "us-east-1b", set = "tgw_attach", nacl = null }                   # REPLACE-WITH customer region's zones
      "10.111.0.48/28" = { az = "us-east-1a", set = "gwlb", nacl = null }                         # REPLACE-WITH customer region's zones
      "10.111.1.48/28" = { az = "us-east-1b", set = "gwlb", nacl = null }                         # REPLACE-WITH customer region's zones
      "10.111.0.64/28" = { az = "us-east-1a", set = "gwlbe_eastwest", nacl = null }               # REPLACE-WITH customer region's zones
      "10.111.1.64/28" = { az = "us-east-1b", set = "gwlbe_eastwest", nacl = null }               # REPLACE-WITH customer region's zones
      "10.111.0.80/28" = { az = "us-east-1a", set = "natgw", nacl = null }                        # REPLACE-WITH customer region's zones
      "10.111.1.80/28" = { az = "us-east-1b", set = "natgw", nacl = null }                        # REPLACE-WITH customer region's zones
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      mgmt_default = {
        vpc_subnet    = "security_vpc-mgmt"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
      mgmt_rfc1918 = {
        vpc_subnet    = "security_vpc-mgmt"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      tgw_rfc1918 = {
        vpc_subnet    = "security_vpc-tgw_attach"
        to_cidr       = "10.0.0.0/8" # Maybe change it to default
        next_hop_key  = "security_gwlb_eastwest"
        next_hop_type = "gwlbe_endpoint"
      }
      tgw_default = {
        vpc_subnet    = "security_vpc-tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_gwlb_eastwest"
        next_hop_type = "gwlbe_endpoint"
      }
      gwlbe_eastwest_rfc1918 = {
        vpc_subnet    = "security_vpc-gwlbe_eastwest"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      gwlbe_eastwest_default = {
        vpc_subnet    = "security_vpc-gwlbe_eastwest"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_nat_gw"
        next_hop_type = "nat_gateway"
      }
      natgw_eastwest_rfc1918 = {
        vpc_subnet    = "security_vpc-natgw"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security_gwlb_eastwest"
        next_hop_type = "gwlbe_endpoint"
      }
      natgw_default = {
        vpc_subnet    = "security_vpc-natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
    }
  }
  app1_vpc = {
    name  = "app1-spoke-vpc"
    cidr  = "10.104.0.0/16"
    nacls = {}
    security_groups = {
      app1_vm = {
        name = "app1_vm"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.104.0.0/24"   = { az = "us-east-1a", set = "app1_vm", nacl = null }
      "10.104.128.0/24" = { az = "us-east-1b", set = "app1_vm", nacl = null }
      "10.104.2.0/24"   = { az = "us-east-1a", set = "app1_lb", nacl = null }
      "10.104.130.0/24" = { az = "us-east-1b", set = "app1_lb", nacl = null }
      "10.104.3.0/24"   = { az = "us-east-1a", set = "app1_gwlbe", nacl = null }
      "10.104.131.0/24" = { az = "us-east-1b", set = "app1_gwlbe", nacl = null }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc_subnet    = "app1_vpc-app1_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1"
        next_hop_type = "transit_gateway_attachment"
      }
      gwlbe_default = {
        vpc_subnet    = "app1_vpc-app1_gwlbe"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_vpc"
        next_hop_type = "internet_gateway"
      }
      lb_default = {
        vpc_subnet    = "app1_vpc-app1_lb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_inbound"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
  app2_vpc = {
    name  = "app2-spoke-vpc"
    cidr  = "10.105.0.0/16"
    nacls = {}
    security_groups = {
      app2_vm = {
        name = "app2_vm"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.105.0.0/24"   = { az = "us-east-1a", set = "app2_vm", nacl = null }
      "10.105.128.0/24" = { az = "us-east-1b", set = "app2_vm", nacl = null }
      "10.105.2.0/24"   = { az = "us-east-1a", set = "app2_lb", nacl = null }
      "10.105.130.0/24" = { az = "us-east-1b", set = "app2_lb", nacl = null }
      "10.105.3.0/24"   = { az = "us-east-1a", set = "app2_gwlbe", nacl = null }
      "10.105.131.0/24" = { az = "us-east-1b", set = "app2_gwlbe", nacl = null }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc_subnet    = "app2_vpc-app2_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2"
        next_hop_type = "transit_gateway_attachment"
      }
      gwlbe_default = {
        vpc_subnet    = "app2_vpc-app2_gwlbe"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_vpc"
        next_hop_type = "internet_gateway"
      }
      lb_default = {
        vpc_subnet    = "app2_vpc-app2_lb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_inbound"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
}

### TRANSIT GATEWAY
tgw = {
  create = true # REPLACE-WITH false, if TGW already exists
  id     = null # REPLACE-WITH TGW id, when create is set to false
  name   = "tgw"
  asn    = "64512"
  route_tables = {
    # Do not change keys `from_security_vpc` and `from_spoke_vpc` as they are used in `main.tf` and attachments
    "from_security_vpc" = {
      create = true
      name   = "from_security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "from_spokes"
    }
  }
  attachments = {
    # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
    # Value of `route_table` and `propagate_routes_to` must match `route_tables` stores under `tgw`
    security = {
      name                = "airs"
      vpc_subnet          = "security_vpc-tgw_attach"
      route_table         = "from_security_vpc"
      propagate_routes_to = "from_spoke_vpc"
    }
    app1 = {
      name                = "app1-spoke-vpc"
      vpc_subnet          = "app1_vpc-app1_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc"
    }
    app2 = {
      name                = "app2-spoke-vpc"
      vpc_subnet          = "app2_vpc-app2_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc"
    }
  }
}

### NAT GATEWAY
# Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
natgws = {
  security_nat_gw = {
    name       = "natgw"
    vpc_subnet = "security_vpc-natgw"
  }
}

### GATEWAY LOADBALANCER
gwlbs = {
  # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
  security_gwlb = {
    name                             = "security-gwlb"
    vpc_subnet                       = "security_vpc-gwlb"
    enable_cross_zone_load_balancing = true
    health_check_port                = 443
  }
}
gwlb_endpoints = {
  # Value of `gwlb` must match key of objects stored in `gwlbs`
  # Value of `vpc` must match key of objects stored in `vpcs`
  # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
  security_gwlb_eastwest = {
    name            = "eastwest-gwlb-endpoint"
    gwlb            = "security_gwlb"
    vpc             = "security_vpc"
    vpc_subnet      = "security_vpc-gwlbe_eastwest"
    act_as_next_hop = false
    to_vpc_subnets  = null
  }
  app1_inbound = {
    name            = "app1-gwlb-endpoint"
    gwlb            = "security_gwlb"
    vpc             = "app1_vpc"
    vpc_subnet      = "app1_vpc-app1_gwlbe"
    act_as_next_hop = true
    to_vpc_subnets  = "app1_vpc-app1_lb"
  }
  app2_inbound = {
    name            = "app2-gwlb-endpoint"
    gwlb            = "security_gwlb"
    vpc             = "app2_vpc"
    vpc_subnet      = "app2_vpc-app2_gwlbe"
    act_as_next_hop = true
    to_vpc_subnets  = "app2_vpc-app2_lb"
  }
}

### VM-SERIES
vmseries_asgs = {
  main_asg = {
    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`
    bootstrap_options = {
      mgmt-interface-swap                   = "enable"
      plugin-op-commands                    = "advance-routing:enable" # TODO: update here
      panorama-server                       = "cloud"
      auth-key                              = "" # TODO: update here
      dgname                                = "AWS-Jam"
      tplname                               = "otid:NHAUdHiNg"
      dhcp-send-hostname                    = "yes"      # TODO: update here
      dhcp-send-client-id                   = "yes"      # TODO: update here
      dhcp-accept-server-hostname           = "yes"      # TODO: update here
      dhcp-accept-server-domain             = "yes"      # TODO: update here
      vm-auth-key                           = ""         # TODO: update here
      authcodes                             = "D4146034" # TODO: update here
      vm-series-auto-registration-pin-id    = "749e05cf-5217-45cd-80a8-d3f495386958"
      vm-series-auto-registration-pin-value = "bf2bb5addded4b49bb7bbc223f62dff0"
    }
    delicense = {
      enabled        = false
      ssm_param_name = null
    }

    instance_name_suffix  = "airs"
    ebs_kms_id            = "alias/aws/ebs"             # TODO: update here

    # Value of `vpc` must match key of objects stored in `vpcs`
    vpc = "security_vpc"

    # Value of `gwlb` must match key of objects stored in `gwlbs`
    gwlb = "security_gwlb"

    # REPLACE-WITH. There might be more than 2 zones, in the region. Make sure to add all the zones in the region or
    # alteast the zones in which applications are presnet.
    interfaces = {
      private = {
        device_index   = 0
        security_group = "vmseries_private"
        subnet = {
          "privatea" = "us-east-1a", # REPLACE-WITH customer region's zones
          "privateb" = "us-east-1b"  # REPLACE-WITH customer region's zones
        }
        create_public_ip  = false
        source_dest_check = false
      }
      mgmt = {
        device_index   = 1
        security_group = "vmseries_mgmt"
        subnet = {
          "mgmta" = "us-east-1a", # REPLACE-WITH customer region's zones
          "mgmtb" = "us-east-1b"  # REPLACE-WITH customer region's zones
        }
        create_public_ip  = true
        source_dest_check = true
      }
    }

    asg = {
      desired_cap                     = 1
      health_check_grace_period       = 1800
      instance_type                   = "c6in.xlarge"
      lambda_execute_pip_install_once = false
      lambda_reserved_concurrent_executions = 2
      max_size                        = 2
      min_size                        = 1
    }

    scaling_plan = {
      enabled                   = true               # TODO: update here
      metric_name               = "panSessionActive" # TODO: update here
      estimated_instance_warmup = 900                # TODO: update here
      target_value              = 75                 # TODO: update here
      statistic                 = "Average"          # TODO: update here
      cloudwatch_namespace      = "asg-airs"         # TODO: update here
      tags = {
        ManagedBy                       = "terraform"
        Product                         = "Palo Alto Networks AI Runtime Security"
        "paloaltonetworks.com-occupied" = "NHAUdHiNg"
        "paloaltonetworks.com-trust"    = "NHAUdHiNg"
      }
    }
    vmseries_ami_id       = "ami-05a4ec5835acaa2f3"
    panos_version = "11.2.3-h1"
    vmseries_product_code = "b261y39exndwe1ltro1tqpeog"
    #launch_template_version = "$Latest"
    instance_refresh = null

    delicense = {
      enabled        = false
      ssm_param_name = null
    }
  }
}

### TC VM
vmseries = {
  tc1 = {
    instances = {
      "01" = { az = "us-east-1a" } # REPLACE-WITH customer region's zones
    }
    instance_type = "c6in.xlarge"

    bootstrap_options = {
      mgmt-interface-swap                   = "disable"
      plugin-op-commands                    = "tag_collector_mode_flag:enable,advance-routing:enable"
      dhcp-send-hostname                    = "yes"
      dhcp-send-client-id                   = "yes"
      dhcp-accept-server-hostname           = "yes"
      dhcp-accept-server-domain             = "yes"
      panorama-server                       = "cloud"
      dgname                                = "AWS-Jam"
      tplname                               = "otid:NHAUdHiNg"
      vm-auth-key                           = "" # TODO: update here
      authcodes                             = "D4146034"
      vm-series-auto-registration-pin-id    = "749e05cf-5217-45cd-80a8-d3f495386958"
      vm-series-auto-registration-pin-value = "bf2bb5addded4b49bb7bbc223f62dff0"
    }

    panos_version         = "11.2.2-h1"
    vmseries_ami_id       = "ami-0d5c6fa1b8f58f7a8"
    vmseries_product_code = "b261y39exndwe1ltro1tqpeog"
    ebs_kms_id            = "alias/aws/ebs"

    # Value of `vpc` must match key of objects stored in `vpcs`
    vpc = "security_vpc"

    interfaces = {
      mgmt = {
        device_index = 0
        private_ip = {
          "01" = "10.111.0.10"
        }
        security_group    = "vmseries_mgmt"
        vpc_subnet        = "security_vpc-mgmt"
        create_public_ip  = true
        source_dest_check = true
        eip_allocation_id = {
          "01" = null
        }
      }
    }
  }
}


### Spoke Compute ###

### SPOKE VMS
spoke_vms = {
  "app1_vm01" = {
    az             = "us-east-1a"
    vpc            = "app1_vpc"
    vpc_subnet     = "app1_vpc-app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app1_vm02" = {
    az             = "us-east-1b"
    vpc            = "app1_vpc"
    vpc_subnet     = "app1_vpc-app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app2_vm01" = {
    az             = "us-east-1a"
    vpc            = "app2_vpc"
    vpc_subnet     = "app2_vpc-app2_vm"
    security_group = "app2_vm"
    type           = "t2.micro"
  }
  "app2_vm02" = {
    az             = "us-east-1b"
    vpc            = "app2_vpc"
    vpc_subnet     = "app2_vpc-app2_vm"
    security_group = "app2_vm"
    type           = "t2.micro"
  }
}

### SPOKE LOADBALANCERS
spoke_lbs = {
  "app1-nlb" = {
    vpc_subnet = "app1_vpc-app1_lb"
    vms        = ["app1_vm01", "app1_vm02"]
  }
  "app2-nlb" = {
    vpc_subnet = "app2_vpc-app2_lb"
    vms        = ["app2_vm01", "app2_vm02"]
  }
}