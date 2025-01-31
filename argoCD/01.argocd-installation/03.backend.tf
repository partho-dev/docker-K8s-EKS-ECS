terraform {
  backend "s3" {
    bucket         = "erg-infra-tf-state"
    key            = "argocd/terraform.tfstate"    # Unique key for ArgoCD
    region         = "us-east-1"
    dynamodb_table = "erg-infra-tf-state-lock"
    encrypt        = true
    profile        = "erg-infra-user"
  }
}