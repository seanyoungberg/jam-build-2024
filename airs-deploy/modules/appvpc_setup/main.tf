
data "aws_vpc_endpoint_service" "this" {
  service_name = var.vpc_endpoint_service.service_name
  service_type = "GatewayLoadBalancer"
  dynamic "filter" {
    for_each = var.vpc_endpoint_service.service_name == null ? [1] : []
    content {
      name   = var.vpc_endpoint_service.tag_name
      values = [var.vpc_endpoint_service.tag_value]
    }
  }
}

resource "aws_subnet" "vpce" {
  for_each = var.gwlb_endpoints

  cidr_block        = each.value.subnet_cidr
  availability_zone = each.value.az
  vpc_id            = var.vpc_id

  tags = merge(var.global_tags, { Name = "${var.name_prefix}gwlbe-subnet" })
}

resource "aws_vpc_endpoint" "vpce" {
  for_each = var.gwlb_endpoints

  # "Only one subnet can be specified for GatewayLoadBalancer" as AWS helpfully says in an error msg. But it still is a one-item set.
  subnet_ids        = [aws_subnet.vpce[each.key].id]
  vpc_endpoint_type = "GatewayLoadBalancer"
  service_name      = data.aws_vpc_endpoint_service.this.service_name
  vpc_id            = var.vpc_id

  tags = merge(var.global_tags, { Name = "${var.name_prefix}gwlbe-${each.value.az}" })
}

locals {
  prot_subnets_k8s = { for k, v in var.gwlb_endpoints : k => v.k8s_subnet_ids }
}

locals {
  prot_subnets_vm = { for k, v in var.gwlb_endpoints : k => v.vm_subnet_ids }
}

data "aws_subnet" "k8s" {
  for_each = toset(flatten([for _, v in local.prot_subnets_k8s : v]))

  filter {
    name   = "subnet-id"
    values = [each.value]
  }
}

data "aws_subnet" "vm" {
  for_each = toset(flatten([for _, v in local.prot_subnets_vm : v]))

  filter {
    name   = "subnet-id"
    values = [each.value]
  }
}

# This route table can be attached to the IGW as Edge association
resource "aws_route_table" "ingress" {
  vpc_id = var.vpc_id
  tags   = merge(var.global_tags, { Name = "${var.name_prefix}ingress-ref-rt" })
}

locals {
  input_routes = flatten([
    for k, v in var.gwlb_endpoints : [
      for sid in v.vm_subnet_ids :
      {
        dst_cidr = data.aws_subnet.vm[sid].cidr_block
        rt_id    = aws_route_table.ingress.id
        vpce_id  = aws_vpc_endpoint.vpce[k].id
      }
    ]
  ])

  flatten_input_routes_vm = { for s in local.input_routes : s.dst_cidr => s }
}

resource "aws_route" "ingress_r" {
  for_each = local.flatten_input_routes_vm

  route_table_id         = each.value.rt_id
  vpc_endpoint_id        = each.value.vpce_id
  destination_cidr_block = each.value.dst_cidr
  # The route matches the exact cidr of a subnet, no less and no more.
  # Routes like these are special in that they are on the "edge", that is they are part of an IGW route table,
  # and AWS allows their destinations to only be:
  #     - The entire IPv4 or IPv6 CIDR block of your VPC. (Not interesting, as we always want AZ-specific next hops.)
  #     - The entire IPv4 or IPv6 CIDR block of a subnet in your VPC. (This is used here.)
  # Source: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table

  # Aside: a VGW has the same rules, except it only supports individual NICs but not GWLB. Such lack
  # of GWLB balancing looks like a temporary AWS limitation.
}

data "aws_ec2_transit_gateway" "this" {
  #count = var.tgw.id == null ? 1 : 0

  # ID of an existing TGW. By default set to `null` hence can be referenced directly.
  id = var.tgw.id

  dynamic "filter" {
    for_each = var.tgw.id == null ? [1] : []
    content {
      name   = var.tgw.tag_name
      values = [var.tgw.tag_value]
    }
  }
}

#data "aws_nat_gateway" "this" {
#    filter {
#        name = "nat-gateway-id"
#        values = [var.natgw]
#    }
#}

# This route table would be attached to VPCe subnet to point to NATGW
# This route table would be used for VM subnets to egress when TGW is not present or egress NAT is not present
#resource "aws_route_table" "vpce" {
#  vpc_id = var.vpc_id
#  route {
#    cidr_block = "0.0.0.0/0"
#    nat_gateway_id = data.aws_nat_gateway.this.id
#  }
##  tags = merge(var.global_tags, { Name = "${var.name_prefix}subnet-egress-natgw-ref-rt" })
#}

data "aws_internet_gateway" "this" {

  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# This route table would be attached to K8S subnet. Default points to IGW
resource "aws_route_table" "k8s" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.this.internet_gateway_id
  }
  tags = merge(var.global_tags, { Name = "${var.name_prefix}subnet-egress-igw-ref-rt" })
}

# This route table would be attached to VM Subnet when TGW is not present.
# 2nd case: TGW present, No NAT GW on security VPC, add rfc1918 specific route to TGW
#resource "aws_route_table" "vm_no_tgw" {
#  for_each = local.flatten_input_routes_vm
#
#  vpc_id = var.vpc_id
#  route {
#    cidr_block      = "0.0.0.0/0"
#    vpc_endpoint_id = each.value.vpce_id
#
#  }
#  tags = merge(var.global_tags, { Name = "${var.name_prefix}subnet-egress-vpce-ref-rt" })
#}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  vpc_id                                          = var.vpc_id
  subnet_ids                                      = toset(flatten([for _, v in local.prot_subnets_vm : v]))
  transit_gateway_id                              = data.aws_ec2_transit_gateway.this.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                                            = merge(var.global_tags, { Name = "${var.name_prefix}tgw-attach-app" })
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = data.aws_ec2_transit_gateway.this.id
}
