output "app_inspected_dns_name" {
  description = <<-EOF
  FQDN of App Internal Load Balancer.
  Can be used in VM-Series configuration to balance traffic between the application instances.
  EOF
  value       = [for l in module.app_lb : l.lb_fqdn]
}

output "gwlb_service" {
  description = "GWLB service name in the security VPC. "
  value       = { for k, v in module.gwlb : k => v.endpoint_service.service_name }
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks_al2023.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = module.eks_al2023.cluster_certificate_authority_data
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks_al2023.cluster_name
}

output "app1_lb_subnet_ids" {
  description = "Subnet IDs for app1_vpc-app1_lb"
  value       = module.subnet_sets["app1_vpc-app1_lb"].subnets
}