### GENERAL
variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}

variable "s3_bucket" {
  description = "AWS region used to deploy whole infrastructure"
  type        = "ts-test"
}
# variable "name_prefix" {
#   description = "Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.)"
#   type        = string
# }
# variable "global_tags" {
#   description = "Global tags configured for all provisioned resources"
# }
