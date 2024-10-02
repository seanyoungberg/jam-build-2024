output "instance_profile_name" {
  value       = aws_iam_instance_profile.this.name
  description = "Name of created IAM instance profile."
}

output "iam_role_name" {
  value       = local.iam_role_name
  description = "Name of created or used IAM role"
}

output "iam_role_arn" {
  value       = local.aws_iam_role.arn
  description = "ARN of created or used IAM role"
}
