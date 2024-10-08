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

variable "unique_id" {
  description = "String prefix to apply to resource names that need to be unique"
  type        = string
  default     = "test"
}

variable "customer_role_name" {
  type = string
  default = ""
}

variable "palo_alto_networks_trusted_entity_role_arn" {
  type = string
  default = ""
}

variable "palo_alto_networks_trusted_entity_role_session_name" {
  type = string
  default = ""
}

variable "customer_aws_s3_logs_bucket" {
  type = string
  default = ""
}

# variable "tsg_id" {
#   description = "The tsg id of customer"
#   type = string
#   default = "1120118569"
# }


