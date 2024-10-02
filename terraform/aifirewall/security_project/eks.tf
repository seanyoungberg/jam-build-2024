##################################################################
# Session Manager VPC Endpoints for app1 VPC
##################################################################

# SSM, EC2Messages, and SSMMessages endpoints are required for Session Manager
resource "aws_vpc_endpoint" "spoke1_ssm" {
  vpc_id              = module.vpc["app1_vpc"].id
  subnet_ids          = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ssm-endpoint" })
}

resource "aws_vpc_endpoint" "spoke1_kms" {
  vpc_id              = module.vpc["app1_vpc"].id
  subnet_ids          = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this
  service_name        = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-kms-endpoint" })
}

resource "aws_vpc_endpoint" "spoke1_ec2messages" {
  vpc_id              = module.vpc["app1_vpc"].id
  subnet_ids          = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ec2messages-endpoint" })
}

resource "aws_vpc_endpoint" "spoke1_ssmmessages" {
  vpc_id              = module.vpc["app1_vpc"].id
  subnet_ids          = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags                = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ssmmessages-endpoint" })
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
  tags               = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-eks-endpoint" })
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags               = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ecr-endpoint" })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags               = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-dkr-endpoint" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = module.vpc["app1_vpc"].id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [module.subnet_sets["app1_vpc-app1_vm"].unique_route_table_ids["us-east-1a"], module.subnet_sets["app1_vpc-app1_vm"].unique_route_table_ids["us-east-1b"]]
  tags            = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-s3-endpoint" })
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags               = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-logs-endpoint" })
}

##################################################################
# EKS Cluster
##################################################################

module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.name_prefix}K8s"
  cluster_version = "1.31"
  cluster_endpoint_public_access = true

  #enable_cluster_creator_admin_permissions = true
  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = {
    # One access entry with a policy associated
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::367521625516:role/sso_admin"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }

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
      name                                   = "${var.name_prefix}K8s-node"
      ami_type                               = "AL2023_x86_64_STANDARD"
      instance_types                         = ["m6i.large"]
      key_name                               = var.ssh_key_name
      iam_role_use_name_prefix               = true
      cluster_security_group_use_name_prefix = true
      iam_role_additional_policies           = { SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
      iam_role_tags                          = var.global_tags

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
            apiVersion: v1
            kind: Service
            metadata:
              name: ui-service
            spec:
              type: LoadBalancer
              ports:
                - port: 8080
                  targetPort: 3000
              selector:
                app: ui
            ---
            apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: ui-deployment
            spec:
              replicas: 1
              selector:
                matchLabels:
                  app: ui
              template:
                metadata:
                  labels:
                    app: ui
                spec:
                  containers:
                    - name: ui
                      image: migara/ui-app
                      ports:
                        - containerPort: 3000
            ---
            apiVersion: v1
            kind: Service
            metadata:
              name: agent-service
            spec:
              type: ClusterIP
              ports:
                - port: 3001
                  targetPort: 3001
              selector:
                app: agent
            ---
            apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: agent-deployment
            spec:
              replicas: 1
              selector:
                matchLabels:
                  app: agent
              template:
                metadata:
                  labels:
                    app: agent
                spec:
                  containers:
                    - name: agent
                      image: migara/agent-app
                      ports:
                        - containerPort: 3001

          EOT
        }
      ]
    }
  }

  tags = var.global_tags
}
