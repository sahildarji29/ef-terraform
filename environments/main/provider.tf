terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Remote state - update these with your actual S3 bucket and DynamoDB table
    bucket         = "eventfarm-terraform-state"
    key            = "environments/main/terraform.tfstate"
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

