##### Security VPC #####

output "aws_vpc_endpoint" {
  description = "VPC endpoints"
  value       = { for v in aws_vpc_endpoint.vpce : v.tags.Name => v.id }
}

output "aws_route_table_ingress" {
  description = "route tables for ingress as reference"
  value       = { "${aws_route_table.ingress.tags.Name}" : aws_route_table.ingress.id }
}

output "aws_route_table_egress_k8s" {
  description = "route tables for k8s egress as reference"
  value       = { "${aws_route_table.k8s.tags.Name}" : aws_route_table.k8s.id }
}
