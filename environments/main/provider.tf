terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "eventfarm-terraform-state"
    key            = "eventfarm/main/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "eventfarm-terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = var.environment
        Cluster     = var.cluster_name
        ManagedBy   = "Terraform"
      }
    )
  }
}

