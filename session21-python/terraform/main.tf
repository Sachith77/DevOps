data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  tags = {
    Project     = "HeroDesk"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = "10.20.0.0/16"
  azs                  = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets      = ["10.20.1.0/24", "10.20.2.0/24"]
  public_subnets       = ["10.20.101.0/24", "10.20.102.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  public_subnet_tags   = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags  = { "kubernetes.io/role/internal-elb" = "1" }
  tags                 = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.kubernetes_version
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = true
  cluster_endpoint_public_access_cidrs     = var.api_allowed_cidrs
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = false

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = {}
    aws-ebs-csi-driver = {
      pod_identity_association = [{
        role_arn        = aws_iam_role.workload["ebs"].arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
    metrics-server = {}
  }

  eks_managed_node_groups = {
    main = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.worker_instance_types
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      disk_size      = 20
    }
  }
  tags = local.tags
}

locals {
  service_accounts = {
    ebs = "ebs-csi-controller-sa"
    lbc = "aws-load-balancer-controller"
  }
}

data "aws_iam_policy_document" "workload_trust" {
  for_each = local.service_accounts
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["kube-system"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [each.value]
    }
  }
}

resource "aws_iam_role" "workload" {
  for_each           = local.service_accounts
  name               = "${var.cluster_name}-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.workload_trust[each.key].json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs" {
  role       = aws_iam_role.workload["ebs"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Upstream controller policy, pinned to the controller version in bootstrap-eks.ps1.
resource "aws_iam_policy" "load_balancer" {
  name   = "${var.cluster_name}-load-balancer"
  policy = file("${path.module}/policies/load-balancer-controller.json")
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "load_balancer" {
  role       = aws_iam_role.workload["lbc"].name
  policy_arn = aws_iam_policy.load_balancer.arn
}

resource "aws_eks_pod_identity_association" "load_balancer" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = local.service_accounts.lbc
  role_arn        = aws_iam_role.workload["lbc"].arn
  depends_on      = [aws_iam_role_policy_attachment.load_balancer]
}
