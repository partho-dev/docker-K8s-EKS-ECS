terraform {
  backend "s3" {
    bucket         = "lia-infra-tf-state"
    key            = "argocd/terraform.tfstate"    # Unique key for ArgoCD
    region         = "us-east-1"
    dynamodb_table = "lia-infra-tf-state-lock"
    encrypt        = true
    profile        = "lia-infra-user"
  }
}