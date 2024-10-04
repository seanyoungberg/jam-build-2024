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