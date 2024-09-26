#Creates cross-account role and attaches trust-relationship policy for the AIRS host assume role
resource "aws_iam_role" "cross_account_assume_role" {
  name = var.customer_role_name
  inline_policy {
    name = "${var.customer_role_name}_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:List*",
          "s3:Get*"],
          "Resource" : [
            "arn:aws:s3:::${var.customer_aws_s3_logs_bucket}",
            "arn:aws:s3:::${var.customer_aws_s3_logs_bucket}/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "eks:AccessKubernetesApi",
            "eks:DescribeCluster",
            "eks:ListClusters"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeKeyPairs",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeInstances",
            "ec2:DescribeVpcs",
            "ec2:DescribeSubnets",
            "ec2:DescribeRegions",
            "ec2:DescribeImages",
            "ec2:DescribeInstanceTypes",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeTransitGateways",
            "ec2:DescribeVpcPeeringConnections",
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "bedrock:ListCustomModels"
          ],
          "Resource" : "*"
        }
      ]
    })
  }
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "${var.palo_alto_networks_trusted_entity_role_arn}"
        },
        Action = "sts:AssumeRole",
      }
    ]
  })
}
