resource "random_id" "sufix" {
  byte_length = 8
}

locals {
  random_name   = "${var.prefix}${random_id.sufix.hex}"
  iam_role_name = coalesce(var.iam_role_name, local.random_name)
  aws_iam_role  = var.create_iam_role_policy ? aws_iam_role.this[0] : data.aws_iam_role.this[0]
}

locals {
  source_root_directory = coalesce(var.source_root_directory, "${path.root}/files")
}


data "aws_iam_role" "this" {
  count = var.create_iam_role_policy == false && var.iam_role_name != null ? 1 : 0

  name = var.iam_role_name
}

# Lookup information about the current AWS partition in which Terraform is working (e.g. `aws`, `aws-us-gov`, `aws-cn`)
data "aws_partition" "this" {}

resource "aws_iam_role" "this" {
  count = var.create_iam_role_policy ? 1 : 0

  name = local.iam_role_name

  tags               = var.global_tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_instance_profile" "this" {
  name = coalesce(var.iam_instance_profile_name, local.random_name)
  role = local.aws_iam_role.name
  path = "/"
}
