##################################################################
# Session Manager VPC Endpoints for app1 VPC
##################################################################

# SSM, EC2Messages, and SSMMessages endpoints are required for Session Manager
resource "aws_vpc_endpoint" "spoke1_ssm" {
  vpc_id     = module.vpc["app1_vpc"].id
  subnet_ids = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ssm-endpoint"})
}

resource "aws_vpc_endpoint" "spoke1_kms" {
  vpc_id     = module.vpc["app1_vpc"].id
  subnet_ids = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this
  service_name      = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-kms-endpoint"})
}

resource "aws_vpc_endpoint" "spoke1_ec2messages" {
  vpc_id     = module.vpc["app1_vpc"].id
  subnet_ids = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ec2messages-endpoint"})
}

resource "aws_vpc_endpoint" "spoke1_ssmmessages" {
  vpc_id     = module.vpc["app1_vpc"].id
  subnet_ids = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ssmmessages-endpoint"})
}


##################################################################
# EKS Endpoints
##################################################################
resource "aws_vpc_endpoint" "eks" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.eks"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-eks-endpoint"})
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ecr-endpoint"})
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-dkr-endpoint"})
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc["app1_vpc"].id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [module.subnet_sets["app1_vpc-app1_vm"].unique_route_table_ids["us-east-1a"], module.subnet_sets["app1_vpc-app1_vm"].unique_route_table_ids["us-east-1b"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-s3-endpoint"})
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-logs-endpoint"})
}

##################################################################
# EKS Cluster
##################################################################

module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.name_prefix}K8s"
  cluster_version = "1.31"

  # EKS Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = module.vpc["app1_vpc"].id
  subnet_ids = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this

  eks_managed_node_groups = {
    managed_node_group_1 = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      name = "${var.name_prefix}K8s-node"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m6i.large"]
      key_name = var.ssh_key_name
      iam_role_use_name_prefix = true
      cluster_security_group_use_name_prefix = true
      iam_role_additional_policies = {SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"}
      iam_role_tags = var.global_tags

      min_size = 2
      max_size = 2
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2

      # This is not required - demonstrates how to pass additional configuration to nodeadm
      # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
      # cloudinit_pre_nodeadm = [
      #   {
      #     content_type = "application/node.eks.aws"
      #     content      = <<-EOT
      #       ---
      #       apiVersion: node.eks.aws/v1alpha1
      #       kind: NodeConfig
      #       spec:
      #         kubelet:
      #           config:
      #             shutdownGracePeriod: 30s
      #             featureGates:
      #               DisableKubeletCloudCredentialProviders: true
      #     EOT
      #   }
      # ]
    }
  }

  tags = var.global_tags
}