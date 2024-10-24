##################################################################
# Private Endpoints in App1 VPC
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

resource "aws_vpc_endpoint" "eks" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.eks"
  vpc_endpoint_type  = "Interface"
  private_dns_enabled = true
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags               = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-eks-endpoint" })
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  private_dns_enabled = true
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags               = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ecr-endpoint" })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  private_dns_enabled = true
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
  private_dns_enabled = true
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags               = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-logs-endpoint" })
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type  = "Interface"
  private_dns_enabled = true
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags               = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-sts-endpoint" })
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id             = module.vpc["app1_vpc"].id
  service_name       = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type  = "Interface"
  private_dns_enabled = true
  subnet_ids         = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id]
  security_group_ids = [module.vpc["app1_vpc"].security_group_ids["app1_vm"]]
  tags               = merge(var.global_tags, { "Name" = "${var.name_prefix}spoke1-ec2-endpoint" })
}


##################################################################
# IAM For EKS Pods
##################################################################

resource "aws_iam_role" "eks_pod_role" {
  name = "${var.name_prefix}eks-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks_al2023.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks_al2023.oidc_provider}:aud" : "sts.amazonaws.com",
            "${module.eks_al2023.oidc_provider}:sub" : "system:serviceaccount:ai-app:eks-pods-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_pod_policy" {
  policy_arn = aws_iam_policy.pod_access_policy.arn
  role       = aws_iam_role.eks_pod_role.name
}

resource "aws_iam_policy" "pod_access_policy" {
  name        = "${var.name_prefix}pod-access-policy"
  path        = "/"
  description = "IAM policy for accessing AWS Bedrock from EKS pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:ListFoundationModels",
          "bedrock:InvokeModelWithResponseStream",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"        ]
        Resource = "*"
      }
    ]
  })
}

##################################################################
# EKS Cluster
##################################################################

module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v20.24.2"

  cluster_name                   = "${var.name_prefix}eks"
  cluster_version                = "1.31"
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  authentication_mode = "API_AND_CONFIG_MAP"

# Got tired of digging through to see if the module pulls these from root or from eks_managed_node_groups nested var. Including in both
  cluster_tags = var.global_tags
  create_cluster_primary_security_group_tags = true
  cluster_security_group_name = "${var.name_prefix}eks-cluster-sg"
  iam_role_name              = "${var.name_prefix}eks-node-role"
  iam_role_additional_policies           = { SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
  iam_role_tags                          = var.global_tags
  node_security_group_name = "${var.name_prefix}eks-node-sg"
  node_security_group_tags = var.global_tags

  # EKS Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni = {
      configuration_values = jsonencode({
        env = [
          {
            name  = "AWS_VPC_K8S_CNI_EXTERNALSNAT"
            value = "false"
          }
        ]
      })
    }
  }

  vpc_id     = module.vpc["app1_vpc"].id
  subnet_ids = [module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1a"].id, module.subnet_sets["app1_vpc-app1_vm"].subnets["us-east-1b"].id] ##TODO fix this

  eks_managed_node_group_defaults = {
    # enable_bootstrap_user_data = true
    ami_type                = "AL2_x86_64"
    pre_bootstrap_user_data = <<-EOT
#!/bin/bash
set -e
# Root CA
cat <<EOF > /tmp/root-ca.crt
-----BEGIN CERTIFICATE-----
MIIDGjCCAgKgAwIBAgIJAOAssb/vAU5uMA0GCSqGSIb3DQEBCwUAMD0xOzA5BgNV
BAMTMlBhbG8gQWx0byBOZXR3b3JrcyAtIFByb2Zlc3Npb25hbCBTZXJ2aWNlcyBS
b290IENBMB4XDTI0MDcyNDA3NTQwN1oXDTI2MDcyNDA3NTQwN1owPTE7MDkGA1UE
AxMyUGFsbyBBbHRvIE5ldHdvcmtzIC0gUHJvZmVzc2lvbmFsIFNlcnZpY2VzIFJv
b3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDHa/VpQeOkKnxG
VoSI4rD8lCWQw19kHPIcs4dGQbyhIy17vVGYM2t6EWYlSiJxOHh/ybtXoPdPd/QJ
EkUGRnLILa9cWFn7hjY6h1G7lGhA4SlaPPXETJ22QHIo3buVhzonwAqf/62LAMlP
S1KlkEWD8Hgx87TENB0MRvThqieVCT/tQXBF1aIoqE8DmIuifYUg3hp6nAnuF7hV
jaWLf6moP3gwP4n0RlEopnnyuNI/ICmNnGmrKnHYYJ2rOJlkRppp6z1jLLtTH8o8
MjFzShoVcWnaP8ME3/MOSKD4a2JOquqi8sd3OmNDhwj3mYWjXRKn502j4LGQNyPU
ZM3geD1tAgMBAAGjHTAbMAwGA1UdEwQFMAMBAf8wCwYDVR0PBAQDAgIEMA0GCSqG
SIb3DQEBCwUAA4IBAQAIgyxijj3wYMuvvI2IcyZANY+HCT7dihAJUwDSbH/SjhGb
GF4F0x/7DN4Gm/4Xfs4S/tcd2l3KAO+MOdc2HLA9LUxdVzinUdl29iUvphtzi1+N
MZ1NDd333oRjxwQaYZaTApXrz2N07Iqc44baob6Cxd8ba1K8s5tJP8kAFdHXzZJN
IEZvWVP6caHWO90xebJSCtKFIox8J1WfCc/EzoGXVUDw0pj9EmQao5UfjTy7Fp1W
rJYc+5k7a43YzRkXB8wG5+Mh17Zg/sxQzxifLA42vgITTzwelLHVHG7JxcdOvjTr
Pf286DbyrucUJefaVPN039H5+oGhlFkgYOBihdGG
-----END CERTIFICATE-----
EOF

# Forward Trust CA
cat <<EOF > /tmp/forward-trust.crt
-----BEGIN CERTIFICATE-----
MIIDHzCCAgegAwIBAgIFAK86Xh4wDQYJKoZIhvcNAQELBQAwPTE7MDkGA1UEAxMy
UGFsbyBBbHRvIE5ldHdvcmtzIC0gUHJvZmVzc2lvbmFsIFNlcnZpY2VzIFJvb3Qg
Q0EwHhcNMjQwNzI0MDc1NDA4WhcNMjYwNzI0MDc1NDA4WjBGMUQwQgYDVQQDEztQ
YWxvIEFsdG8gTmV0d29ya3MgLSBQcm9mZXNzaW9uYWwgU2VydmljZXMgRm9yd2Fy
ZCBUcnVzdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOfCSWc9
lA2YIh1IVq5UmQn46dpXM61nvw3B4blCDXg/dfm9qYMGth3SlWyeGJAAbibogMtE
+HRV9Tpg6vlC2SuvGAhYGSpknJLFe8TvLA6yR8VsYz0O4v61AwFo3zypjE5Rcj9H
TvC28urHWhVm19ELMok12czQP3wLHHOw75iOhSRh5ofu6kN3MII/e98e5UrlRCiW
CxzGBX4k+In/zk42nRoJEOmFUoy2Up+PpdTbaTmvshaWtkOOneAjktEuefF20Q76
fuL1KzbtQcAsa4XK1rDMUV5G5m6zpldd7Ul+wrBrU+dxEOAkg8V1KIi83jHdLaod
rRAW5Hyv+5aRFP8CAwEAAaMdMBswDAYDVR0TBAUwAwEB/zALBgNVHQ8EBAMCAgQw
DQYJKoZIhvcNAQELBQADggEBAD1CwUMiKS0PdWDmWy3WS1zj5KQ5HVQm7YoUeNGu
bLU/dPAlL7jpH7vH78E65QRLlpPsQ+G9uLV/fMKepoBcfv9jLuDAxf09R92fsN48
hrxdtSS54eGXZ5ZjTI0GryPfEDzlqxwwDHfzu2DDoGKNFIsGGPB5ctR5bS9J+az1
Z/lVf9k0zqWLf4fUFC9YgjUbUVfVQ8uXWlo1IlUaKrpIWaQpx5+5czgEDYeAQCTG
ELAyKzh+ZXi5zuV+xi21ZjI86QZKOuvz2cC3tAWkT2litn8+PbmqfPlUlQlJAaGK
SG4LH8EtivrRGXDTIfvU76dPcpIL0a2CymPBWwkA0xvHNIY=
-----END CERTIFICATE-----
EOF

# Forward Trust CA
cat <<EOF > /tmp/forward-trust.crt
-----BEGIN CERTIFICATE-----
MIIDHzCCAgegAwIBAgIFAK86Xh4wDQYJKoZIhvcNAQELBQAwPTE7MDkGA1UEAxMy
UGFsbyBBbHRvIE5ldHdvcmtzIC0gUHJvZmVzc2lvbmFsIFNlcnZpY2VzIFJvb3Qg
Q0EwHhcNMjQwNzI0MDc1NDA4WhcNMjYwNzI0MDc1NDA4WjBGMUQwQgYDVQQDEztQ
YWxvIEFsdG8gTmV0d29ya3MgLSBQcm9mZXNzaW9uYWwgU2VydmljZXMgRm9yd2Fy
ZCBUcnVzdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOfCSWc9
lA2YIh1IVq5UmQn46dpXM61nvw3B4blCDXg/dfm9qYMGth3SlWyeGJAAbibogMtE
+HRV9Tpg6vlC2SuvGAhYGSpknJLFe8TvLA6yR8VsYz0O4v61AwFo3zypjE5Rcj9H
TvC28urHWhVm19ELMok12czQP3wLHHOw75iOhSRh5ofu6kN3MII/e98e5UrlRCiW
CxzGBX4k+In/zk42nRoJEOmFUoy2Up+PpdTbaTmvshaWtkOOneAjktEuefF20Q76
fuL1KzbtQcAsa4XK1rDMUV5G5m6zpldd7Ul+wrBrU+dxEOAkg8V1KIi83jHdLaod
rRAW5Hyv+5aRFP8CAwEAAaMdMBswDAYDVR0TBAUwAwEB/zALBgNVHQ8EBAMCAgQw
DQYJKoZIhvcNAQELBQADggEBAD1CwUMiKS0PdWDmWy3WS1zj5KQ5HVQm7YoUeNGu
bLU/dPAlL7jpH7vH78E65QRLlpPsQ+G9uLV/fMKepoBcfv9jLuDAxf09R92fsN48
hrxdtSS54eGXZ5ZjTI0GryPfEDzlqxwwDHfzu2DDoGKNFIsGGPB5ctR5bS9J+az1
Z/lVf9k0zqWLf4fUFC9YgjUbUVfVQ8uXWlo1IlUaKrpIWaQpx5+5czgEDYeAQCTG
ELAyKzh+ZXi5zuV+xi21ZjI86QZKOuvz2cC3tAWkT2litn8+PbmqfPlUlQlJAaGK
SG4LH8EtivrRGXDTIfvU76dPcpIL0a2CymPBWwkA0xvHNIY=
-----END CERTIFICATE-----
EOF

# Forward Untrust CA
cat <<EOF > /tmp/forward-untrust.crt
-----BEGIN CERTIFICATE-----
MIIDITCCAgmgAwIBAgIFAK86Xh8wDQYJKoZIhvcNAQELBQAwPTE7MDkGA1UEAxMy
UGFsbyBBbHRvIE5ldHdvcmtzIC0gUHJvZmVzc2lvbmFsIFNlcnZpY2VzIFJvb3Qg
Q0EwHhcNMjQwNzI0MDc1NDA5WhcNMjYwNzI0MDc1NDA5WjBIMUYwRAYDVQQDEz1Q
YWxvIEFsdG8gTmV0d29ya3MgLSBQcm9mZXNzaW9uYWwgU2VydmljZXMgRm9yd2Fy
ZCBVblRydXN0IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3WhF
RMqT3Cb6rSVEmqVWXOgm2ACsX4dEIl2wcBrMig3jSLAdSu6CGya6JHbmjXJFbkuI
trXh1IKM6ok59NcZmz66yIYewlp/NqYn+uvgVbI/fod/qmpvaMmcxCJIwGMdApY4
9/nPFE8WgMTtgHA8hcFZT3+WxmbkgQ52DpIIVlLrzxjTi+YQ8ez90W6GRtJfHljm
vjCtjvxe9+Ji6xyG6Kd3x8bWmgewBiOnTdbvSsbdNyniOUfCPnczCFSfr+uT/MT6
QIevjrEjdhkTNk5n1tZtM9kMfDLoMFoP657e0MewD+xogwmrXrmSQBK8ehnnHGyY
uJjlyadCfq76ThDRiQIDAQABox0wGzAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIC
BDANBgkqhkiG9w0BAQsFAAOCAQEAKzPFa7RbmZLCwkMGXVfnh7FtIYqUxW9XNNvv
lY8ZS+ZvB1CdaaAd94fKiy9+ZAdrAa3/iqn095GARcoJm9e7pdOpyxjAO/3JFi+v
lSn8hwSGxDi90W8Sk4hv7KSDnExta6/u5AQqRxxo+SMPAlgSFNnKVh0RwR4z8OlW
tGG9I8JkGKZ4jMP5fTlZ1jVjomFS4A9Ry4IJG3Hh5ahQdAAaVTA5w9flqrPjAvBV
Sw76it2H0fcbI6FjUm0wzs+lOcrezm+oQ9xUPaae4WUFM7ckONm16uhEhU6Tde+F
+OjMoFgyF7ev9y06iSxciIArddrCt/NhmLMLPR7TtpeKoSkAKA==
-----END CERTIFICATE-----
EOF

# Forward Trust CA ECDSA
cat <<EOF > /tmp/forward-trust-ecdsa.crt
-----BEGIN CERTIFICATE-----
MIICTjCCATagAwIBAgIFAK86XiAwDQYJKoZIhvcNAQELBQAwPTE7MDkGA1UEAxMy
UGFsbyBBbHRvIE5ldHdvcmtzIC0gUHJvZmVzc2lvbmFsIFNlcnZpY2VzIFJvb3Qg
Q0EwHhcNMjQwNzI2MTU1NjI4WhcNMjYwNzI2MTU1NjI4WjBAMT4wPAYDVQQDEzVQ
YWxvIEFsdG8gTmV0d29ya3MgLSBQcm9mZXNzaW8gRm9yd2FyZCBUcnVzdCBDQSBF
Q0RTQTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABNY50W+eGgWpi095vOB04aCI
B6/4hpCKRIg+qPUqb4z3BsRiDJOidHWJuvI7xmVH1vpm2QB3AoWU3EdX4ofvwf+j
HTAbMAwGA1UdEwQFMAMBAf8wCwYDVR0PBAQDAgIEMA0GCSqGSIb3DQEBCwUAA4IB
AQAWYCruDPP+3Rb4V29gMSmK5Z1RqBKtJFU2LtVNK20jJgiVe09BI8OtDQwCZ976
KoOS0NVum0y7x5xJADGhlY92vNxRVUxzQouHn33da/Fh1HkUbZ9an/3Vwhbz8Mr7
Nsm9lMZ3BaXkEp6n6N42OwiI63WQX3qtYO9mGkFODw7s8xLDl9lKvOjc1sJjVKM5
WJfjzRBnxdRw5a0CQJsTGuRoPckPZI5lQZqJTlwkcNjfmpW+dgXx+RxDrLgtdzVa
iDNmw4fMYHbD3scDLNDTmWuYEFbt0g+tseP9UtLkF6LZqxouhpLq5WxThe1hq/+0
DHbV9slSjUfg6CNtsJLHFK/N
-----END CERTIFICATE-----
EOF

# Forward Unrust CA ECDSA
cat <<EOF > /tmp/forward-untrust-ecdsa.crt
-----BEGIN CERTIFICATE-----
MIICUDCCATigAwIBAgIFAK86XiEwDQYJKoZIhvcNAQELBQAwPTE7MDkGA1UEAxMy
UGFsbyBBbHRvIE5ldHdvcmtzIC0gUHJvZmVzc2lvbmFsIFNlcnZpY2VzIFJvb3Qg
Q0EwHhcNMjQwNzI2MTU1NjI4WhcNMjYwNzI2MTU1NjI4WjBCMUAwPgYDVQQDEzdQ
YWxvIEFsdG8gTmV0d29ya3MgLSBQcm9mZXNzaW8gRm9yd2FyZCBVblRydXN0IENB
IEVDRFNBMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEy2AnZKqq8cdcSyLK712z
KLYJnOPC5olmRQde6BjGsg0KKCnOG+zztPYLy8+1DJsVu2RiHjSmFS+4A/JLul8X
zKMdMBswDAYDVR0TBAUwAwEB/zALBgNVHQ8EBAMCAgQwDQYJKoZIhvcNAQELBQAD
ggEBAFh/VAXmuJ8xKikIw+pGxxw+lvTW/Cn/Fe3wzCuLcIpEYNJeAGANK7d8qw+O
E13/h2jfl6jZn4aLe3Kp+xRyfxzzlAPYHqW5XUiWq7LZ8jZaok+tn6JrLMwCSfYU
2leLPhCIgZkZQ9fjYYzCk6RQZWhK0qemaOwN9uZKJYhvmxhpEY+4hkB1f/S4hJFD
pUngF8u1fcqV+OmNGkMGtOs6bbpuoaEzoScUKktrtuLh8nPLVJz6/QdJS7cXCAUv
G5aMi+cBocbP3JvxHyoKLST4b2eSS8A8AvM1HXNvuwuV/r74jG2OD9MuP4u+8cql
tMoF9UirnnGEQgnng37TDUOUtYk=
-----END CERTIFICATE-----
EOF


# Add all certificates to the trust store
cp /tmp/*.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

# Clean up
rm /tmp/*.crt
EOT

  }
  eks_managed_node_groups = {
    managed_node_group_1 = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      name = "${var.name_prefix}eks-node-group"
      # ami_type                               = "AL2023_x86_64_STANDARD"
      # instance_types                         = ["m6i.large"]
      instance_types                         = ["t3.small"]
      key_name                               = data.aws_key_pair.ec2.key_name
      cluster_tags = var.global_tags
      create_cluster_primary_security_group_tags = true
      cluster_security_group_name = "${var.name_prefix}eks-cluster-sg"
      launch_template_name =  "${var.name_prefix}eks-node-launch"
      launch_template_tags = var.global_tags
      iam_role_name              = "${var.name_prefix}eks-node-role"
      iam_role_additional_policies           = { SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
      iam_role_tags                          = var.global_tags
      node_security_group_name = "${var.name_prefix}eks-node-sg"
      node_security_group_tags = var.global_tags

      min_size = 1
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 1

      #pre_bootstrap_user_data = file("${path.module}/add_ca.sh")


      # This is not required - demonstrates how to pass additional configuration to nodeadm
      # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/     
      #cloudinit_pre_nodeadm = []
      
    }
  }

  tags = var.global_tags
}

## Set IAM role mapping

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
#   version = "~> 20.0"

#   manage_aws_auth_configmap = true

#   aws_auth_roles = [
#     {
#       rolearn  = var.user_iam_role
#       username = "labuser"
#       groups   = ["system:masters"]
#     },
#     {
#       rolearn  = var.codebuild_iam_role
#       username = "codebuild"
#       groups   = ["system:masters"]
#     },
#   ]
#   depends_on = [module.eks_al2023]
# }

resource "null_resource" "aws_auth_configmap" {
  depends_on = [module.eks_al2023]

  provisioner "local-exec" {
    command = <<EOT
set -e

aws eks wait cluster-active --name ${var.name_prefix}eks --region ${var.region}

aws eks update-kubeconfig --name ${var.name_prefix}eks --region ${var.region} --kubeconfig kubeconfig_${var.name_prefix}eks

export KUBECONFIG=kubeconfig_${var.name_prefix}eks

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${var.user_iam_role}
      username: labuser
      groups:
        - system:masters
    - rolearn: ${var.codebuild_iam_role}
      username: codebuild
      groups:
        - system:masters
    - rolearn: ${module.eks_al2023.eks_managed_node_groups["managed_node_group_1"].iam_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF
EOT
    interpreter = ["/bin/bash", "-c"]
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes        = all
  }
}


