variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
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
  description = "Main application domain (e.g., app.example.com)"
  type        = string
}

variable "api_domain" {
  description = "API endpoint domain (e.g., api.example.com)"
  type        = string
}

variable "login_domain" {
  description = "Authentication domain (e.g., login.example.com)"
  type        = string
}

variable "base_domain" {
  description = "Base domain for SSL certificates (e.g., example.com)"
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
  description = "Docker image URI for app service (e.g., your-registry/app:latest)"
  type        = string
  default     = ""
}

variable "api2_image" {
  description = "Docker image URI for api2 service"
  type        = string
  default     = ""
}

variable "canvas_image" {
  description = "Docker image URI for canvas service"
  type        = string
  default     = ""
}

variable "process_job_worker_image" {
  description = "Docker image URI for process-job-worker service"
  type        = string
  default     = ""
}

variable "urltopng_image" {
  description = "Docker image URI for urltopng service"
  type        = string
  default     = ""
}

variable "gearman_server_image" {
  description = "Docker image URI for gearman-server service"
  type        = string
  default     = ""
}

variable "scheduler_image" {
  description = "Docker image URI for scheduler service"
  type        = string
  default     = ""
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
  description = "Service discovery namespace name (e.g., your-app.local)"
  type        = string
  default     = ""
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
  description = "MySQL database password - Use SSM Parameter ARN or leave empty to reference existing parameter"
  type        = string
  default     = ""
  sensitive   = true
}

# MongoDB Configuration
variable "mongodb_host" {
  description = "MongoDB host"
  type        = string
  default     = ""
}

variable "mongodb_user" {
  description = "MongoDB user"
  type        = string
  default     = ""
}

variable "mongodb_password" {
  description = "MongoDB password (should use Secrets Manager instead)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mongodb_database" {
  description = "MongoDB database name"
  type        = string
  default     = ""
}

variable "mongodb_email_database" {
  description = "MongoDB email database name"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

