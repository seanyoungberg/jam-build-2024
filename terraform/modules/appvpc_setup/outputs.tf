output "aws_tgw_vpc_attachment" {
  description = "TGW attachments"
  value       = { for t in aws_ec2_transit_gateway_vpc_attachment.this : t.tags.Name => t.id }
}

output "aws_vpc_endpoint" {
  description = "VPC endpoints"
  value       = { for v in aws_vpc_endpoint.vpce : v.tags.Name => v.id }
}

output "aws_route_table_ingress" {
  description = "route tables for ingress as reference"
  value       = { "${aws_route_table.ingress.tags.Name}" : aws_route_table.ingress.id }
}

output "aws_route_table_k8s_egress_igw" {
  description = "route tables for k8s egress as reference"
  value       = { "${aws_route_table.k8s.tags.Name}" : aws_route_table.k8s.id }
}

output "aws_route_table_vm_egress_tgw" {
  description = "route tables for VM egress with TGW as reference"
  value       = { "${aws_route_table.vm_tgw.tags.Name}" : aws_route_table.vm_tgw.id }
}

output "aws_route_table_vm_egress_vpce" {
  description = "route tables for VM egress with VPC endpoint as reference"
  value       = [for rt in aws_route_table.vm_no_tgw : ["${rt.tags.Name}", rt.id]]
}
