# SSM Parameter Store - Environment Variables and Secrets
#
# Simple rule: If you add a variable here, it will be created in SSM and injected into the container.
# If you don't add it, it won't exist. That's it!
#
# All parameters are stored as SecureString (encrypted) in AWS SSM Parameter Store.
#
# To add a new environment variable:
#   1. Find the service block (app, api2, worker, etc.)
#   2. Add your variable with value and description
#   3. Done!
#
# Example:
#   "NEW_API_KEY" = {
#     value       = var.new_api_key
#     description = "API key for new service"
#   }

locals {
  # Shared/common parameters used by multiple services
  common_params = {
    "EF_ENV" = {
      value       = var.environment
      description = "Event Farm environment name"
    }
    "CLUSTER" = {
      value       = var.cluster_name
      description = "Cluster name"
    }
    "APP_ENV" = {
      value       = var.app_env
      description = "Application environment (production, staging, etc.)"
    }
  }

  # App Service - Main application
  app_env_vars = merge(local.common_params, {
    "DOMAIN" = {
      value       = var.domain
      description = "Main domain"
    }
    "API_DOMAIN" = {
      value       = var.api_domain
      description = "API domain"
    }
    "LOGIN_DOMAIN" = {
      value       = var.login_domain
      description = "Login domain"
    }
    "BASE_DOMAIN" = {
      value       = var.base_domain
      description = "Base domain"
    }
    "SCHEME" = {
      value       = "http"
      description = "URL scheme (http/https)"
    }
    "SERVICE_DISCOVERY_NAMESPACE" = {
      value       = var.enable_service_discovery ? var.service_discovery_namespace : ""
      description = "Service discovery namespace"
    }
    "MYSQL_HOST" = {
      value       = var.database_host
      description = "MySQL database host"
    }
    "MYSQL_USER" = {
      value       = var.database_user
      description = "MySQL database user"
    }
    "MYSQL_PASSWORD" = {
      value       = var.database_password
      description = "MySQL database password"
    }
    "MYSQL_DATABASE" = {
      value       = var.database_name
      description = "MySQL database name"
    }
    "BASE_URI" = {
      value       = "${var.acm_certificate_arn != "" ? "https" : "http"}://${var.domain}"
      description = "Base application URI"
    }
    "API2_BASE_URI" = {
      value       = "${var.acm_certificate_arn != "" ? "https" : "http"}://${var.domain}/api"
      description = "API2 base URI"
    }
    "LOGIN_BASE_URI" = {
      value       = "${var.acm_certificate_arn != "" ? "https" : "http"}://${var.login_domain}"
      description = "Login base URI"
    }
    "SCHEDULER_BASE_URI" = {
      value       = "http://scheduler.${var.enable_service_discovery ? var.service_discovery_namespace : "eventfarm.local"}:4000"
      description = "Scheduler service base URI"
    }
    "GEARMAN_BASE_URI" = {
      value       = "http://gearman-server.${var.enable_service_discovery ? var.service_discovery_namespace : "eventfarm.local"}:4730"
      description = "Gearman server base URI"
    }
    "DEBUG" = {
      value       = "0"
      description = "Debug mode flag"
    }
    "APP_DEBUG" = {
      value       = "false"
      description = "Application debug flag"
    }
    "SHOW_EXCEPTIONS" = {
      value       = "false"
      description = "Show exceptions flag"
    }
    # Add Twilio variables only if you need them - if not, just remove these lines
    "TWILIO_SID" = {
      value       = var.twilio_sid
      description = "Twilio Account SID"
    }
    "TWILIO_TOKEN" = {
      value       = var.twilio_token
      description = "Twilio Auth Token"
    }
    "TWILIO_MSG_SERVICE_SID" = {
      value       = var.twilio_msg_service_sid
      description = "Twilio Messaging Service SID"
    }
    "TWILIO_MSG_STATUS_CALLBACK_URL" = {
      value       = var.twilio_msg_status_callback_url
      description = "Twilio message status callback URL"
    }
    # Add MongoDB variables only if you need them - if not, just remove these lines
    "MONGO_HOST" = {
      value       = var.mongodb_host
      description = "MongoDB host"
    }
    "MONGO_USER" = {
      value       = var.mongodb_user
      description = "MongoDB user"
    }
    "MONGO_PASSWORD" = {
      value       = var.mongodb_password
      description = "MongoDB password"
    }
    "MONGO_DATABASE" = {
      value       = var.mongodb_database
      description = "MongoDB database name"
    }
    "MONGO_EMAIL_DATABASE" = {
      value       = var.mongodb_email_database
      description = "MongoDB email database name"
    }
  })

  # API2 Service - API endpoints
  api2_env_vars = merge(local.common_params, {
    "API_DOMAIN" = {
      value       = var.api_domain
      description = "API domain"
    }
    "MYSQL_HOST" = {
      value       = var.database_host
      description = "MySQL database host"
    }
    "MYSQL_USER" = {
      value       = var.database_user
      description = "MySQL database user"
    }
    "MYSQL_PASSWORD" = {
      value       = var.database_password
      description = "MySQL database password"
    }
    "MYSQL_DATABASE" = {
      value       = var.database_name
      description = "MySQL database name"
    }
    "BASE_URI" = {
      value       = "${var.acm_certificate_arn != "" ? "https" : "http"}://${var.domain}"
      description = "Base application URI"
    }
    "API2_BASE_URI" = {
      value       = "${var.acm_certificate_arn != "" ? "https" : "http"}://${var.domain}/api"
      description = "API2 base URI"
    }
    "DEBUG" = {
      value       = "0"
      description = "Debug mode flag"
    }
    "APP_DEBUG" = {
      value       = "false"
      description = "Application debug flag"
    }
    "SHOW_EXCEPTIONS" = {
      value       = "false"
      description = "Show exceptions flag"
    }
    "TWILIO_SID" = {
      value       = var.twilio_sid
      description = "Twilio Account SID"
    }
    "TWILIO_TOKEN" = {
      value       = var.twilio_token
      description = "Twilio Auth Token"
    }
    "TWILIO_MSG_SERVICE_SID" = {
      value       = var.twilio_msg_service_sid
      description = "Twilio Messaging Service SID"
    }
    "TWILIO_MSG_STATUS_CALLBACK_URL" = {
      value       = var.twilio_msg_status_callback_url
      description = "Twilio message status callback URL"
    }
  })

  # Worker Service - Background job processing
  worker_env_vars = merge(local.common_params, {
    "GEARMAN_HOST" = {
      value       = var.enable_service_discovery ? "gearman-server.${var.service_discovery_namespace}" : "gearman-server"
      description = "Gearman server hostname"
    }
    "GEARMAN_PORT" = {
      value       = "4730"
      description = "Gearman server port"
    }
  })

  # Canvas Service - Canvas rendering
  canvas_env_vars = local.common_params

  # URL to PNG Service - Screenshot generation
  urltopng_env_vars = {
    "NODE_ENV" = {
      value       = "production"
      description = "Node.js environment"
    }
    "STORAGE_PROVIDER" = {
      value       = "s3"
      description = "Storage provider (s3, local, etc.)"
    }
    "AWS_REGION" = {
      value       = var.aws_region
      description = "AWS region for S3 storage"
    }
    "PUPPETEER_WAIT_UNTIL" = {
      value       = "networkidle2"
      description = "Puppeteer wait condition for page load"
    }
  }

  # Scheduler Service - Scheduled tasks
  scheduler_env_vars = local.common_params

  # Gearman Service - Job queue server
  gearman_env_vars = {
    "VERBOSE" = {
      value       = "INFO"
      description = "Gearman server verbosity level"
    }
  }

  # Combine all service env vars into a single map for SSM parameter creation
  # This deduplicates parameters - if same key exists in multiple services, it's only created once
  all_env_vars = merge(
    local.app_env_vars,
    local.api2_env_vars,
    local.worker_env_vars,
    local.canvas_env_vars,
    local.urltopng_env_vars,
    local.scheduler_env_vars,
    local.gearman_env_vars
  )

  # SSM parameter path prefix
  parameter_prefix = "/${var.cluster_name}/${var.environment}"
}

# Create SSM parameters - ALL parameters are SecureString (encrypted at rest)
# This is hardcoded to ensure all environment variables are encrypted
resource "aws_ssm_parameter" "parameter" {
  for_each = local.all_env_vars

  name  = "${local.parameter_prefix}/${each.key}"
  type  = "SecureString"  # All env vars are encrypted - no exceptions
  value = each.value.value

  description = try(each.value.description, "Environment variable for ${var.cluster_name} cluster")

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-${each.key}"
      Environment = var.environment
      Cluster     = var.cluster_name
      Parameter   = each.key
    }
  )
}

# Build secrets arrays for ECS task definitions
# ECS expects: { name = "VAR_NAME", valueFrom = "ssm:/path/to/param" }
locals {
  parameter_names = {
    for k, v in aws_ssm_parameter.parameter : k => v.name
  }

  # Service secrets arrays
  app_secrets = [
    for key, config in local.app_env_vars : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  api2_secrets = [
    for key, config in local.api2_env_vars : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  worker_secrets = [
    for key, config in local.worker_env_vars : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  canvas_secrets = [
    for key, config in local.canvas_env_vars : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  urltopng_secrets = [
    for key, config in local.urltopng_env_vars : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  scheduler_secrets = [
    for key, config in local.scheduler_env_vars : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  gearman_secrets = [
    for key, config in local.gearman_env_vars : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]
}
