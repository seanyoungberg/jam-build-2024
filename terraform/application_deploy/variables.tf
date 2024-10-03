variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}
variable "name_prefix" {
  description = "Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.)"
  type        = string
  default     = ""
}
variable "global_tags" {
  description = "Global tags configured for all provisioned resources"
  default     = {}
}
variable "ssh_key_name" {
  description = "Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes"
  type        = string
  default     = ""
}

variable "unique_id" {
  description = "String prefix to apply to resource names that need to be unique"
  type        = string
  default     = "test"
}

variable "flow_log_bucket" {
  description = "Existing bucket to send VPC flow logs"
  type        = string
  default     = ""
}

# variable "eks_cluster_endpoint" {
#   description = "EKS cluster endpoint"
#   type        = string
# }

# variable "eks_cluster_ca_certificate" {
#   description = "EKS cluster CA certificate"
#   type        = string
# }

# variable "eks_cluster_name" {
#   description = "EKS cluster name"
#   type        = string
# }

# variable "app1_lb_subnet_ids" {
#   description = "Subnet IDs for app1_vpc-app1_lb"
#   type        = map(object({
#     id = string
#   }))
# }

variable "terraform_state_bucket" {
  description = "The name of the S3 bucket for Terraform state"
  type        = string
}

variable "infra_state_key" {
  description = "The key for the infrastructure project's state file in S3"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}