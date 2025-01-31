output "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed."
  value       = module.vpc.vpc_id
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS Kubernetes API."
  value       = module.eks.cluster_endpoint    
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "region" {
  description = "Region where the EKS cluster is deployed."
  value       = var.region
}

