provider "aws" {
#   region  = local.region
  region = "ap-south-1"
  profile = "test-eks"
}

terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "main" {
#   name = local.cluster_name
name = "My-EKS"
}

data "aws_eks_cluster_auth" "main" {
  name = data.aws_eks_cluster.main.name
}

# 1. Create IAM Group
resource "aws_iam_group" "admin_group" {
  name = "admin-group"
}

# 2. Create IAM Role for Admin Group with Trust relationship and AssumeRole permission
resource "aws_iam_role" "adminGroupRole" {
  name = "adminGroupRole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }
  ]
}
POLICY
}

# 3. Create Admin Policy (Full Access to EKS)
resource "aws_iam_policy" "adminPolicy" {
  name        = "adminPolicy"
  description = "Full access to all resources, including EKS"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

# 4. Attach Admin Policy to Admin Group (Full Access to Group)
resource "aws_iam_group_policy_attachment" "attach_admin_policy_to_group" {
  group      = aws_iam_group.admin_group.name
  policy_arn = aws_iam_policy.adminPolicy.arn
}

# 5. Attach the Admin Policy to the Admin Group Role
resource "aws_iam_role_policy_attachment" "attach_admin_policy_to_role" {
  role       = aws_iam_role.adminGroupRole.name
  policy_arn = aws_iam_policy.adminPolicy.arn

  depends_on = [
    aws_iam_policy.adminPolicy,
    aws_iam_role.adminGroupRole
  ]
}

# 6. Create AssumeRole Policy for the Group to Assume adminGroupRole
resource "aws_iam_policy" "eks_assume_admin" {
  name = "AmazonEKSAssumeAdminPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "${aws_iam_role.adminGroupRole.arn}"
        }
    ]
}
POLICY
}

# 7. Attach AssumeRole Policy to the Admin Group
resource "aws_iam_policy_attachment" "attach_eks_assume_admin_policy" {
  name       = "eks-assume-admin-policy-attachment"
  groups     = [aws_iam_group.admin_group.name]
  policy_arn = aws_iam_policy.eks_assume_admin.arn
}

# 8. Create IAM User for the Admin Group
resource "aws_iam_user" "partho_admin_1" {
  name = "partho-admin-1"
}

# 9. Add Users to the Admin Group
resource "aws_iam_user_group_membership" "admin_group_membership" {
  user   = aws_iam_user.partho_admin_1.name
  groups = [aws_iam_group.admin_group.name]
}

# 10. Link IAM Role to EKS using aws_eks_access_entry
resource "aws_eks_access_entry" "admin" {
  cluster_name      = data.aws_eks_cluster.main.name
  principal_arn     = aws_iam_role.adminGroupRole.arn
  kubernetes_groups = ["Admin-Group"]
  type              = "STANDARD"
}

output "aws_eks_cluster" {
  value = data.aws_eks_cluster.main.name
}

output "aws_cluster_url" {
  value = data.aws_eks_cluster.main.endpoint
}
