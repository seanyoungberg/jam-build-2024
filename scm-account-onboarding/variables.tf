variable "customer_aws_region" {
  type    = string
  default = ""
}

variable "customer_role_name" {
  type    = string
  default = ""
}

variable "customer_aws_profile" {
  type    = string
  default = ""
}

variable "palo_alto_networks_trusted_entity_role_arn" {
  type    = string
  default = ""
}

variable "palo_alto_networks_trusted_entity_role_session_name" {
  type    = string
  default = ""
}

variable "customer_aws_s3_logs_bucket" {
  type    = string
  default = ""
}

variable "customer_terraform_state_bucket_name" {
  description = "The name of the bucket where you would store the terraform state"
  type        = string
  default     = ""
}

variable "tsg_id" {
  description = "The tsg id of customer"
  type        = string
  default     = ""
}
