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
