variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (prod, prelive, dev)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster (e.g., blue, teal, lime)"
  type        = string
}

# VPC Configuration
variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

# Domain Configuration
variable "domain" {
  description = "Main domain (e.g., app.eventfarm.com)"
  type        = string
}

variable "api_domain" {
  description = "API domain (e.g., api.eventfarm.com)"
  type        = string
}

variable "login_domain" {
  description = "Login domain (e.g., login.eventfarm.com)"
  type        = string
}

variable "base_domain" {
  description = "Base domain (e.g., eventfarm.com)"
  type        = string
}

# Service Scaling
variable "app_scale" {
  description = "Desired count for app service"
  type        = number
  default     = 4
}

variable "api2_scale" {
  description = "Desired count for api2 service"
  type        = number
  default     = 4
}

variable "worker_scale" {
  description = "Desired count for process-job-worker service"
  type        = number
  default     = 20
}

variable "urltopng_scale" {
  description = "Desired count for urltopng service"
  type        = number
  default     = 2
}

# Docker Images
variable "app_image" {
  description = "Docker image for app service"
  type        = string
  default     = "membersuite/app:auth0"
}

variable "api2_image" {
  description = "Docker image for api2 service"
  type        = string
  default     = "membersuite/api2:7.3.28"
}

variable "canvas_image" {
  description = "Docker image for canvas service"
  type        = string
  default     = "membersuite/canvas:latest"
}

variable "process_job_worker_image" {
  description = "Docker image for process-job-worker service"
  type        = string
  default     = "membersuite/process-job-worker:8.4.5-dev"
}

variable "urltopng_image" {
  description = "Docker image for urltopng service"
  type        = string
  default     = "jasonraimondi/url-to-png:0.11.0"
}

variable "gearman_server_image" {
  description = "Docker image for gearman-server service"
  type        = string
  default     = "artefactual/gearmand:1.1.19.1-alpine"
}

variable "scheduler_image" {
  description = "Docker image for scheduler service"
  type        = string
  default     = "membersuite/scheduler:1.6.0"
}

# ECR Configuration
variable "use_ecr" {
  description = "Use ECR instead of Docker Hub for images"
  type        = bool
  default     = false
}

variable "app_image_tag" {
  description = "Image tag for app service (used when use_ecr = true)"
  type        = string
  default     = "auth0"
}

variable "api2_image_tag" {
  description = "Image tag for api2 service (used when use_ecr = true)"
  type        = string
  default     = "7.3.28"
}

variable "canvas_image_tag" {
  description = "Image tag for canvas service (used when use_ecr = true)"
  type        = string
  default     = "latest"
}

variable "process_job_worker_image_tag" {
  description = "Image tag for process-job-worker service (used when use_ecr = true)"
  type        = string
  default     = "8.4.5-dev"
}

variable "urltopng_image_tag" {
  description = "Image tag for urltopng service (used when use_ecr = true)"
  type        = string
  default     = "0.11.0"
}

variable "gearman_server_image_tag" {
  description = "Image tag for gearman-server service (used when use_ecr = true)"
  type        = string
  default     = "1.1.19.1-alpine"
}

variable "scheduler_image_tag" {
  description = "Image tag for scheduler service (used when use_ecr = true)"
  type        = string
  default     = "1.6.0"
}

# Docker Hub Credentials (for private images)
variable "dockerhub_username" {
  description = "Docker Hub username for private repository access"
  type        = string
  default     = ""
  sensitive   = true
}

variable "dockerhub_password" {
  description = "Docker Hub password or access token for private repository access"
  type        = string
  default     = ""
  sensitive   = true
}

variable "dockerhub_secret_arn" {
  description = "ARN of existing Secrets Manager secret for Docker Hub credentials (optional - will create if not provided)"
  type        = string
  default     = ""
}

# Resource Sizing
variable "app_cpu" {
  description = "CPU units for app task (1024 = 1 vCPU)"
  type        = number
  default     = 2048
}

variable "app_memory" {
  description = "Memory for app task in MB"
  type        = number
  default     = 4096
}

variable "api2_cpu" {
  description = "CPU units for api2 task"
  type        = number
  default     = 1024
}

variable "api2_memory" {
  description = "Memory for api2 task in MB"
  type        = number
  default     = 2048
}

variable "worker_cpu" {
  description = "CPU units for worker task"
  type        = number
  default     = 512
}

variable "worker_memory" {
  description = "Memory for worker task in MB"
  type        = number
  default     = 1024
}

# CloudWatch Logs
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Service Discovery
variable "enable_service_discovery" {
  description = "Enable AWS Service Discovery"
  type        = bool
  default     = true
}

variable "service_discovery_namespace" {
  description = "Service discovery namespace name"
  type        = string
  default     = "eventfarm.local"
}

# Auto Scaling
variable "enable_auto_scaling" {
  description = "Enable auto scaling for services"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Minimum capacity for auto scaling"
  type        = map(number)
  default = {
    app    = 2
    api2   = 2
    worker = 5
  }
}

variable "max_capacity" {
  description = "Maximum capacity for auto scaling"
  type        = map(number)
  default = {
    app    = 10
    api2   = 10
    worker = 50
  }
}

# Security
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "database_security_group_id" {
  description = "Security group ID for RDS/MySQL access"
  type        = string
  default     = ""
}

# Environment Variables
variable "app_env" {
  description = "Application environment (production, staging, etc.)"
  type        = string
  default     = "production"
}

variable "twilio_sid" {
  description = "Twilio Account SID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "twilio_token" {
  description = "Twilio Auth Token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "twilio_msg_service_sid" {
  description = "Twilio Messaging Service SID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "twilio_msg_status_callback_url" {
  description = "Twilio message status callback URL"
  type        = string
  default     = ""
}

variable "mongodb_security_group_id" {
  description = "Security group ID for MongoDB access"
  type        = string
  default     = ""
}

# ACM Certificate
variable "acm_certificate_arn" {
  description = "ARN of existing ACM certificate (leave empty to create new)"
  type        = string
  default     = ""
}

# Tags
variable "database_host" {
  description = "MySQL database host"
  type        = string
  default     = ""
}

variable "database_name" {
  description = "MySQL database name"
  type        = string
  default     = ""
}

variable "database_user" {
  description = "MySQL database user"
  type        = string
  default     = ""
}

variable "database_password" {
  description = "MySQL database password (should use Secrets Manager instead)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

