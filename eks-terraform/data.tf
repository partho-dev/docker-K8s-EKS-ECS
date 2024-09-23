data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_eks_cluster_auth" "auth" {
  name = var.cluster_name
}
