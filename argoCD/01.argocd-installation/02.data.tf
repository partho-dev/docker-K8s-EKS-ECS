#Get the specific EKS from aws
data "aws_eks_cluster" "eks" {
  name = "lia-infra-eks-dev"
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.eks.name
}