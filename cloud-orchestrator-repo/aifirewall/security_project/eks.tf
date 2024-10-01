resource "aws_vpc_endpoint" "eks" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.eks"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc["app1_vpc"].id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [module.subnet_sets["app1_vpc-app1_vm"].unique_route_table_ids["us-east-1a"], module.subnet_sets["app1_vpc-app1_vm"].unique_route_table_ids["us-east-1b"]]
}

module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.name_prefix}-K8s"
  cluster_version = "1.30"

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
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = ["m6i.large"]

      min_size = 2
      max_size = 2
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2

      # This is not required - demonstrates how to pass additional configuration to nodeadm
      # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
      cloudinit_pre_nodeadm = [
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  shutdownGracePeriod: 30s
                  featureGates:
                    DisableKubeletCloudCredentialProviders: true
          EOT
        }
      ]
    }
  }

  tags = var.global_tags
}