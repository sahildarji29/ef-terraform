terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure if using remote state
  # backend "s3" {
  #   bucket = "eventfarm-terraform-state"
  #   key    = "environments/prelive/terraform.tfstate"
  #   region = "us-east-1"
  #   encrypt = true
  #   dynamodb_table = "terraform-state-lock"
  # }
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

