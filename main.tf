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
  #   key    = "ecs-fargate/${var.cluster_name}/terraform.tfstate"
  #   region = "us-east-1"
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

# Data source for existing VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Data source for existing subnets
data "aws_subnets" "public" {
  filter {
    name   = "subnet-id"
    values = var.public_subnet_ids
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "subnet-id"
    values = var.private_subnet_ids
  }
}

# Get availability zones for subnets
data "aws_subnet" "public" {
  for_each = toset(var.public_subnet_ids)
  id       = each.value
}

data "aws_subnet" "private" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.cluster_name}/app"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api2" {
  name              = "/ecs/${var.cluster_name}/api2"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "process_job_worker" {
  name              = "/ecs/${var.cluster_name}/process-job-worker"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "canvas" {
  name              = "/ecs/${var.cluster_name}/canvas"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "urltopng" {
  name              = "/ecs/${var.cluster_name}/urltopng"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "gearman_server" {
  name              = "/ecs/${var.cluster_name}/gearman-server"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "scheduler" {
  name              = "/ecs/${var.cluster_name}/scheduler"
  retention_in_days = var.log_retention_days
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.cluster_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.app.name
      }
    }
  }
}

# Service Discovery Namespace (optional)
resource "aws_service_discovery_private_dns_namespace" "main" {
  count = var.enable_service_discovery ? 1 : 0
  name  = var.service_discovery_namespace
  vpc   = var.vpc_id
}

