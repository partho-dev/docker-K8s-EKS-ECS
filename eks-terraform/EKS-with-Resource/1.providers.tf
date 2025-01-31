provider "aws" {
  region = local.region
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


