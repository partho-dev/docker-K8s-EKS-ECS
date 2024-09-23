# output "eks_cluster_endpoint" {
#   description = "Endpoint for the EKS Kubernetes API."
#   value       = aws_eks_cluster.eks_cluster.endpoint
# }

output "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed."
  value       = module.vpc.vpc_id
}
