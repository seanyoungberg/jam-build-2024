### GENERAL
region      = "us-west-2" # REPLACE-WITH customer region
name_prefix = "jam-"      # REPLACE-WITH prefix to be used in deployment

global_tags = {
  ManagedBy                       = "terraform"
  Application                     = "Palo Alto Networks VM-Series NGFW"
  "paloaltonetworks.com-occupied" = "JGxv3U6Sg"
  "paloaltonetworks.com-trust"    = "JGxv3U6Sg"
  Owner                           = "PS Team"
}

ssh_key_name = "shared-ps-key" # REPLACE-WITH Keypair created

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
      "10.111.0.0/28"  = { az = "us-west-2a", set = "mgmt", nacl = null }                         # REPLACE-WITH customer region's zones
      "10.111.1.0/28"  = { az = "us-west-2b", set = "mgmt", nacl = null }                         # REPLACE-WITH customer region's zones
      "10.111.0.16/28" = { az = "us-west-2a", set = "private", nacl = "trusted_path_monitoring" } # REPLACE-WITH customer region's zones
      "10.111.1.16/28" = { az = "us-west-2b", set = "private", nacl = "trusted_path_monitoring" } # REPLACE-WITH customer region's zones
      "10.111.0.32/28" = { az = "us-west-2a", set = "tgw_attach", nacl = null }                   # REPLACE-WITH customer region's zones
      "10.111.1.32/28" = { az = "us-west-2b", set = "tgw_attach", nacl = null }                   # REPLACE-WITH customer region's zones
      "10.111.0.48/28" = { az = "us-west-2a", set = "gwlb", nacl = null }                         # REPLACE-WITH customer region's zones
      "10.111.1.48/28" = { az = "us-west-2b", set = "gwlb", nacl = null }                         # REPLACE-WITH customer region's zones
      "10.111.0.64/28" = { az = "us-west-2a", set = "gwlbe_eastwest", nacl = null }               # REPLACE-WITH customer region's zones
      "10.111.1.64/28" = { az = "us-west-2b", set = "gwlbe_eastwest", nacl = null }               # REPLACE-WITH customer region's zones
      "10.111.0.80/28" = { az = "us-west-2a", set = "natgw", nacl = null }                        # REPLACE-WITH customer region's zones
      "10.111.1.80/28" = { az = "us-west-2b", set = "natgw", nacl = null }                        # REPLACE-WITH customer region's zones
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
        vpc           = "security_vpc-tgw_attach"
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
}

### VM-SERIES
vmseries_asgs = {
  main_asg = {
    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`
    bootstrap_options = {
      mgmt-interface-swap                   = "enable"
      plugin-op-commands                    = "aws-gwlb-inspect:enable,advance-routing:enable" # TODO: update here
      panorama-server                       = "cloud"
      auth-key                              = "" # TODO: update here
      dgname                                = "AWS-Jam"
      tplname                               = "otid:JGxv3U6Sg"
      dhcp-send-hostname                    = "yes"      # TODO: update here
      dhcp-send-client-id                   = "yes"      # TODO: update here
      dhcp-accept-server-hostname           = "yes"      # TODO: update here
      dhcp-accept-server-domain             = "yes"      # TODO: update here
      vm-auth-key                           = ""         # TODO: update here
      authcodes                             = "D4869931" # TODO: update here
      vm-series-auto-registration-pin-id    = "df46e162-2ff8-4710-be2d-9d427ff1da3c"
      vm-series-auto-registration-pin-value = "8a7645d4bb2e4cf2a8866eb370fa13fb"
    }

    instance_name_suffix  = "airs"
    panos_version         = "10.2.9-h1"                 # TODO: update here
    vmseries_product_code = "6njl1pau431dv1qxipg63mvah" # TODO: update here
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
          "privatea" = "us-west-2a", # REPLACE-WITH customer region's zones
          "privateb" = "us-west-2b"  # REPLACE-WITH customer region's zones
        }
        create_public_ip  = false
        source_dest_check = false
      }
      mgmt = {
        device_index   = 1
        security_group = "vmseries_mgmt"
        subnet = {
          "mgmta" = "us-west-2a", # REPLACE-WITH customer region's zones
          "mgmtb" = "us-west-2b"  # REPLACE-WITH customer region's zones
        }
        create_public_ip  = true
        source_dest_check = true
      }
    }

    asg = {
      desired_cap                     = 1
      min_size                        = 0
      max_size                        = 1
      instance_type                   = "c6in.xlarge" # REPLACE-WITH image preferred
      lambda_execute_pip_install_once = false
      health_check_grace_period       = 1800
    }

    scaling_plan = {
      enabled                   = true               # TODO: update here
      metric_name               = "panSessionActive" # TODO: update here
      estimated_instance_warmup = 900                # TODO: update here
      target_value              = 75                 # TODO: update here
      statistic                 = "Average"          # TODO: update here
      cloudwatch_namespace      = "asg-airs"         # TODO: update here
      tags = {
        ManagedBy = "terraform"
      }
    }
    vmseries_ami_id = "ami-0bd4da9665d951e18" # REPLACE-WITH Custom AMI
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
    vmseries_ami_id = "ami-0bd4da9665d951e18"
    instances = {
      "01" = { az = "ap-northeast-3a" } # REPLACE-WITH customer region's zones
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
      tplname                               = "otid:JGxv3U6Sg"
      vm-auth-key                           = "" # TODO: update here
      authcodes                             = "D4869931"
      vm-series-auto-registration-pin-id    = "df46e162-2ff8-4710-be2d-9d427ff1da3c"
      vm-series-auto-registration-pin-value = "8a7645d4bb2e4cf2a8866eb370fa13fb"
    }

    panos_version         = "10.2.3"
    vmseries_product_code = "6njl1pau431dv1qxipg63mvah"
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
