### VPCS ###

module "vpc" {
  source = "../modules/vpc"

  for_each = var.vpcs

  name       = "${var.name_prefix}${each.value.name}"
  cidr_block = each.value.cidr
  #nacls                   = each.value.nacls
  security_groups         = each.value.security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
  global_tags             = var.global_tags
}

### Flow Logs ###

resource "aws_flow_log" "vpc_flow_logs" {
  for_each = module.vpc

  log_destination      = var.flow_log_bucket
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = each.value.id

  tags = merge(
    var.global_tags,
    {
      Name = "${var.name_prefix}FlowLog-${each.key}"
    }
  )
}

### SUBNETS ###

module "subnet_sets" {
  for_each = toset(flatten([for _, v in { for vk, vv in var.vpcs : vk => distinct([for sk, sv in vv.subnets : "${vk}-${sv.set}"]) } : v]))
  source   = "../modules/subnet_set"

  name                = split("-", each.key)[1]
  name_prefix         = var.name_prefix
  vpc_id              = module.vpc[split("-", each.key)[0]].id
  has_secondary_cidrs = module.vpc[split("-", each.key)[0]].has_secondary_cidrs
  global_tags         = var.global_tags

  cidrs = {
    for i in flatten([
      for vk, vv in var.vpcs : [
        for sk, sv in vv.subnets :
        {
          cidr : sk,
          subnet : sv
        } if each.key == "${vk}-${sv.set}"
    ]]) : i.cidr => i.subnet
  }
}

### ROUTES ###

locals {
  vpc_routes = flatten(concat([
    for vk, vv in var.vpcs : [
      for rk, rv in vv.routes : {
        subnet_key = rv.vpc_subnet
        to_cidr    = rv.to_cidr
        next_hop_set = (
          rv.next_hop_type == "internet_gateway" ? module.vpc[rv.next_hop_key].igw_as_next_hop_set : (
            rv.next_hop_type == "nat_gateway" ? module.natgw_set[rv.next_hop_key].next_hop_set : (
              rv.next_hop_type == "transit_gateway_attachment" ? module.transit_gateway_attachment[rv.next_hop_key].next_hop_set : (
                rv.next_hop_type == "gwlbe_endpoint" ? module.gwlbe_endpoint[rv.next_hop_key].next_hop_set : null
              )
            )
          )
        )
      }
    ]
  ]))
}

module "vpc_routes" {
  for_each = { for route in local.vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../modules/vpc_route"

  route_table_ids = module.subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

### NATGW ###

module "natgw_set" {
  source = "../modules/nat_gateway_set"

  for_each = var.natgws

  subnets     = module.subnet_sets[each.value.vpc_subnet].subnets
  global_tags = var.global_tags
}

### TGW ###

module "transit_gateway" {
  source = "../modules/transit_gateway"

  create       = var.tgw.create
  id           = var.tgw.id
  name         = "${var.name_prefix}${var.tgw.name}"
  asn          = var.tgw.asn
  route_tables = var.tgw.route_tables
  tags         = var.global_tags
}

### TGW ATTACHMENTS ###

module "transit_gateway_attachment" {
  source = "../modules/transit_gateway_attachment"

  for_each = var.tgw.attachments

  name                        = "${var.name_prefix}${each.value.name}"
  vpc_id                      = module.subnet_sets[each.value.vpc_subnet].vpc_id
  subnets                     = module.subnet_sets[each.value.vpc_subnet].subnets
  transit_gateway_route_table = module.transit_gateway.route_tables[each.value.route_table]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables[each.value.propagate_routes_to].id
  }
  tags = var.global_tags
}

resource "aws_ec2_transit_gateway_route" "from_spokes_to_security" {
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_spoke_vpc"].id
  transit_gateway_attachment_id  = module.transit_gateway_attachment["security"].attachment.id
  destination_cidr_block         = "0.0.0.0/0"
  blackhole                      = false
}

### GWLB ###

module "gwlb" {
  source = "../modules/gwlb"

  for_each = var.gwlbs

  name                             = "${var.name_prefix}${each.value.name}"
  vpc_id                           = module.subnet_sets[each.value.vpc_subnet].vpc_id
  subnets                          = module.subnet_sets[each.value.vpc_subnet].subnets
  enable_cross_zone_load_balancing = each.value.enable_cross_zone_load_balancing
  health_check_port                = each.value.health_check_port
  global_tags                      = var.global_tags
}

### GWLB ENDPOINTS ###

module "gwlbe_endpoint" {
  source = "../modules/gwlb_endpoint_set"

  for_each = var.gwlb_endpoints

  name              = "${var.name_prefix}${each.value.name}"
  gwlb_service_name = module.gwlb[each.value.gwlb].endpoint_service.service_name
  vpc_id            = module.subnet_sets[each.value.vpc_subnet].vpc_id
  subnets           = module.subnet_sets[each.value.vpc_subnet].subnets

  act_as_next_hop_for = each.value.act_as_next_hop ? {
    "from-igw-to-lb" = {
      route_table_id = module.vpc[each.value.vpc].internet_gateway_route_table.id
      to_subnets     = module.subnet_sets[each.value.to_vpc_subnets].subnets
    }
    # The routes in this section are special in that they are on the "edge", that is they are part of an IGW route table,
    # and AWS allows their destinations to only be:
    #     - The entire IPv4 or IPv6 CIDR block of your VPC. (Not interesting, as we always want AZ-specific next hops.)
    #     - The entire IPv4 or IPv6 CIDR block of a subnet in your VPC. (This is used here.)
    # Source: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table
  } : {}
}

### SPOKE VM INSTANCES ####

data "aws_ami" "this" {
  most_recent = true # newest by time, not by version number

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  owners = ["137112412989"]
}

data "aws_ebs_default_kms_key" "current" {
}

data "aws_kms_alias" "current_arn" {
  name = data.aws_ebs_default_kms_key.current.key_arn
}

# IAM Role
resource "aws_iam_role" "spoke_vm_ec2_iam_role" {
  name = "${var.name_prefix}spoke_vm"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# IAM Policy Document
data "aws_iam_policy_document" "spoke_vm_policy" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:ListFoundationModels"
    ]
    resources = ["*"]
  }
}

# IAM Policy
resource "aws_iam_policy" "spoke_vm_policy" {
  name        = "${var.name_prefix}spoke_vm_policy"
  path        = "/"
  description = "IAM policy for spoke VM EC2 instance"
  policy      = data.aws_iam_policy_document.spoke_vm_policy.json
}

# Custom Policy Attachment
resource "aws_iam_role_policy_attachment" "spoke_vm_policy_attach" {
  role       = aws_iam_role.spoke_vm_ec2_iam_role.name
  policy_arn = aws_iam_policy.spoke_vm_policy.arn
}

# AWS Managed Policy Attachment
resource "aws_iam_role_policy_attachment" "spoke_vm_iam_instance_policy" {
  role       = aws_iam_role.spoke_vm_ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile
resource "aws_iam_instance_profile" "spoke_vm_iam_instance_profile" {
  name = "${var.name_prefix}spoke_vm_instance_profile"
  role = aws_iam_role.spoke_vm_ec2_iam_role.name
}


resource "aws_instance" "spoke_vms" {
  for_each = var.spoke_vms

  ami                    = data.aws_ami.this.id
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  subnet_id              = module.subnet_sets[each.value.vpc_subnet].subnets[each.value.az].id
  vpc_security_group_ids = [module.vpc[each.value.vpc].security_group_ids[each.value.security_group]]
  tags                   = merge({ Name = "${var.name_prefix}${each.key}" }, var.global_tags)
  iam_instance_profile   = aws_iam_instance_profile.spoke_vm_iam_instance_profile.name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_kms_alias.current_arn.target_key_arn
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = <<EOF
Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
until yum update -y; do echo "Retrying"; sleep 5; done
until yum install -y httpd; do echo "Retrying"; sleep 5; done
systemctl start httpd
systemctl enable httpd
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="custom_script.txt"

#!/bin/bash
# Update the system and install necessary packages
yum update -y
yum install -y python3 python3-pip awscli

# Set up a directory for your scripts
mkdir -p /opt/myscripts
cd /opt/myscripts

# Download the main script and Python scripts from S3
aws s3 cp s3://aws-jam-challenge-resources-"${var.region}"/paloalto-ai-runtime-security/execute_scripts_aws.sh .
aws s3 cp s3://aws-jam-challenge-resources-"${var.region}"/paloalto-ai-runtime-security/aws_bedrock_llama.py .
aws s3 cp s3://aws-jam-challenge-resources-"${var.region}"/paloalto-ai-runtime-security/aws_bedrock_llama_threat.py .
aws s3 cp s3://aws-jam-challenge-resources-"${var.region}"/paloalto-ai-runtime-security/aws_bedrock_llama3.py .
aws s3 cp s3://aws-jam-challenge-resources-"${var.region}"/paloalto-ai-runtime-security/aws_bedrock_llama3_pj.py .


# Make the main script executable
chmod +x execute_scripts_aws.sh

# Set up a systemd service to run your script
cat <<EOT > /etc/systemd/system/myscript.service
[Unit]
Description=My Script Service
After=network.target

[Service]
ExecStart=/opt/myscripts/execute_scripts_aws.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOT

# Enable and start the service
systemctl enable myscript.service
systemctl start myscript.service

--//--
EOF
}

### SPOKE INBOUND NETWORK LOAD BALANCER ###

module "app_lb" {
  source = "../modules/nlb"

  for_each = var.spoke_lbs

  name        = "${var.name_prefix}${each.key}"
  internal_lb = false
  subnets     = { for k, v in module.subnet_sets[each.value.vpc_subnet].subnets : k => { id = v.id } }
  vpc_id      = module.subnet_sets[each.value.vpc_subnet].vpc_id

  balance_rules = {
    "SSH" = {
      protocol    = "TCP"
      port        = "22"
      target_type = "instance"
      stickiness  = true
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
    "HTTP" = {
      protocol    = "TCP"
      port        = "80"
      target_type = "instance"
      stickiness  = false
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
    "HTTPS" = {
      protocol    = "TCP"
      port        = "443"
      target_type = "instance"
      stickiness  = false
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
  }

  tags = var.global_tags
}

### GWLB ASSOCIATIONS WITH VM-Series ENDPOINTS ###
locals {
  plugin_op_commands_with_endpoints_mapping = { for i, j in var.vmseries_asgs : i => format("%s", j.bootstrap_options["plugin-op-commands"]) }
  bootstrap_options_with_endpoints_mapping = { for i, j in var.vmseries_asgs : i => [
  for k, v in j.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping[i]}"] }
}

### IAM ROLES AND POLICIES ###

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

resource "aws_iam_role" "vm_series_ec2_iam_role" {
  name               = "${var.name_prefix}airs"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {"Service": "ec2.amazonaws.com"}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "vm_series_ec2_iam_policy" {
  role   = aws_iam_role.vm_series_ec2_iam_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricData",
        "cloudwatch:ListMetrics"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DescribeAlarms"
      ],
      "Resource": [
        "arn:${data.aws_partition.this.partition}:cloudwatch:${var.region}:${data.aws_caller_identity.this.account_id}:alarm:*"
      ],
      "Effect": "Allow"
    }
  ]
}

EOF
}

resource "aws_iam_instance_profile" "vm_series_iam_instance_profile" {

  name = "${var.name_prefix}airs_instance_profile"
  role = aws_iam_role.vm_series_ec2_iam_role.name
}

### AUTOSCALING GROUP WITH VM-Series INSTANCES ###

module "vm_series_asg" {
  source = "../modules/asg"

  for_each = var.vmseries_asgs

  ssh_key_name                    = var.ssh_key_name
  region                          = var.region
  name_prefix                     = var.name_prefix
  global_tags                     = var.global_tags
  instance_name_suffix            = each.value.instance_name_suffix
  vmseries_version                = each.value.panos_version
  vmseries_product_code           = each.value.vmseries_product_code
  max_size                        = each.value.asg.max_size
  min_size                        = each.value.asg.min_size
  instance_type                   = each.value.asg.instance_type
  desired_capacity                = each.value.asg.desired_cap
  health_check_grace_period       = each.value.asg.health_check_grace_period
  lambda_execute_pip_install_once = each.value.asg.lambda_execute_pip_install_once
  instance_refresh                = each.value.instance_refresh
  #launch_template_version         = each.value.launch_template_version
  vmseries_ami_id               = each.value.vmseries_ami_id
  vmseries_iam_instance_profile = aws_iam_instance_profile.vm_series_iam_instance_profile.name
  subnet_ids                    = [for i, j in var.vpcs[each.value.vpc].subnets : module.subnet_sets[format("%s-lambda", each.value.vpc)].subnets[j.az].id if j.set == "lambda"]
  security_group_ids            = contains(keys(module.vpc[each.value.vpc].security_group_ids), "lambda") ? [module.vpc[each.value.vpc].security_group_ids["lambda"]] : []
  interfaces = {
    for k, v in each.value.interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.vpc[each.value.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = { for z, c in v.subnet : c => module.subnet_sets[format("%s-%s", each.value.vpc, k)].subnets[c].id }
      create_public_ip   = try(v.create_public_ip, false)
    }
  }
  #ebs_kms_id        = each.value.ebs_kms_id
  target_group_arn     = module.gwlb[each.value.gwlb].target_group.arn
  bootstrap_options    = join(";", compact(concat(local.bootstrap_options_with_endpoints_mapping[each.key])))
  scaling_plan_enabled = each.value.scaling_plan.enabled
  scaling_metric_name  = each.value.scaling_plan.metric_name
  #scaling_estimated_instance_warmup = each.value.scaling_plan.estimated_instance_warmup
  scaling_target_value         = each.value.scaling_plan.target_value
  scaling_statistic            = each.value.scaling_plan.statistic
  scaling_cloudwatch_namespace = each.value.scaling_plan.cloudwatch_namespace
  scaling_tags                 = merge(each.value.scaling_plan.tags, { prefix : var.name_prefix })

  delicense_ssm_param_name = each.value.delicense.ssm_param_name
  delicense_enabled        = each.value.delicense.enabled
}

### BOOTSTRAP PACKAGE
module "bootstrap" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }
  source   = "../modules/bootstrap"

  iam_role_name             = "${var.name_prefix}tc_vm${each.value.instance}"
  iam_instance_profile_name = "${var.name_prefix}tc_vm_instance_profile${each.value.instance}"

  prefix      = var.name_prefix
  global_tags = var.global_tags

  bootstrap_options     = merge(each.value.common.bootstrap_options, { hostname = "${var.name_prefix}${each.key}" })
  source_root_directory = "files-${each.key}/"
}

### VM-Series INSTANCES

locals {
  vmseries_instances = flatten([for kv, vv in var.vmseries : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, common = vv }]])
}

module "vmseries" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }
  source   = "../modules/vmseries"

  name                  = "${var.name_prefix}${each.key}"
  vmseries_version      = each.value.common.panos_version
  vmseries_ami_id       = each.value.common.vmseries_ami_id
  vmseries_product_code = each.value.common.vmseries_product_code
  instance_type         = each.value.common.instance_type

  interfaces = {
    for k, v in each.value.common.interfaces : k => {
      device_index       = v.device_index
      private_ips        = [v.private_ip[each.value.instance]]
      security_group_ids = try([module.vpc[each.value.common.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = module.subnet_sets[v.vpc_subnet].subnets[each.value.az].id
      create_public_ip   = try(v.create_public_ip, false)
      eip_allocation_id  = try(v.eip_allocation_id[each.value.instance], null)
    }
  }

  bootstrap_options = join(";", compact(concat(
    ["mgmt-interface-swap=${each.value.common.bootstrap_options["mgmt-interface-swap"]}"],
    ["plugin-op-commands=${each.value.common.bootstrap_options["plugin-op-commands"]}"],
    ["vm-auth-key=${each.value.common.bootstrap_options["vm-auth-key"]}"],
    ["dgname=${each.value.common.bootstrap_options["dgname"]}"],
    ["tplname=${each.value.common.bootstrap_options["tplname"]}"],
    ["dhcp-send-hostname=${each.value.common.bootstrap_options["dhcp-send-hostname"]}"],
    ["dhcp-send-client-id=${each.value.common.bootstrap_options["dhcp-send-client-id"]}"],
    ["dhcp-accept-server-hostname=${each.value.common.bootstrap_options["dhcp-accept-server-hostname"]}"],
    ["dhcp-accept-server-domain=${each.value.common.bootstrap_options["dhcp-accept-server-domain"]}"],
    ["panorama-server=${each.value.common.bootstrap_options["panorama-server"]}"],
    ["authcodes=${each.value.common.bootstrap_options["authcodes"]}"],
    ["vm-series-auto-registration-pin-id=${each.value.common.bootstrap_options["vm-series-auto-registration-pin-id"]}"],
    ["vm-series-auto-registration-pin-value=${each.value.common.bootstrap_options["vm-series-auto-registration-pin-value"]}"],
  )))

  iam_instance_profile = module.bootstrap[each.key].instance_profile_name
  ssh_key_name         = var.ssh_key_name
  tags                 = var.global_tags
}


