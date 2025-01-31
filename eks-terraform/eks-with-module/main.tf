# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Name        = var.vpc_name
    Environment = var.environment
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                   = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"          = 1
  }
}

# IAM Role for EKS Control Plane
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.cluster_name}-cluster-role"
    Environment = var.environment
  }
}

# Attach Policies to EKS Control Plane Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "eks-node-role"
    Environment = var.environment
  }
}

# Attach Policies to EKS Node Role
resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  # version         = "20.20.0"
  version         = "~> 19.0"  # Update to the latest version or a specific version you'd like to use

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  # IAM Role for EKS Control Plane
  iam_role_arn = aws_iam_role.eks_cluster_role.arn

  # Enable IRSA for the EKS cluster which associates IAM roles to K8s service accounts.
  enable_irsa = true


  # Enable logging for the EKS control plane
#   enable_logging = true
  create_cloudwatch_log_group = true
  cluster_enabled_log_types   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Node group configuration
  eks_managed_node_groups = {
    "${var.cluster_name}-nodes" = {
      desired_capacity = var.desired_capacity
      max_capacity     = var.max_capacity
      min_capacity     = var.min_capacity
      instance_types    = [var.instance_type]
      instance_type = var.instance_type
      key_name         = var.key_name

      update_config = {
        max_unavailable_percentage=33
      }

      create_security_group = false


      iam_role_arn = aws_iam_role.eks_node_role.arn

      iam_role_name="${var.cluster_name}-node-group-role"
      name="${var.cluster_name}-node-group"
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # Cluster endpoint access settings
  cluster_endpoint_public_access = true  #make it false if you want to access the cluster only from private subnets
  cluster_endpoint_private_access = true #this will ensure the cluster is only accessible from within the VPC

  tags = {
    Environment = var.environment
    "k8s.io/cluster-autoscaler/enabled" = true
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }
}
