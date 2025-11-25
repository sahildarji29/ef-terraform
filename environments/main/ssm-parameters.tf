# SSM Parameter Store - environment variables and secrets placed here
#
# To add a new environment variable:
#   1. Add it to the ssm_parameters map below
#   2. Add the parameter name to the service's parameter_keys list (app_parameter_keys, etc.)
#   3. Run terraform plan/apply
#
# Parameter types:
#   - All parameters use SecureString (encrypted at rest) for security
#
# Example: Adding STRIPE_API_KEY for app service
#   1. Add to ssm_parameters: "STRIPE_API_KEY" = { value = var.stripe_api_key, type = "SecureString", description = "Stripe API key" }
#   2. Add "STRIPE_API_KEY" to app_parameter_keys list
#   3. That's it - it'll show up as STRIPE_API_KEY env var in the app container

locals {
  # All SSM parameters.
  ssm_parameters = {
    "EF_ENV" = {
      value       = var.environment
      type        = "SecureString"
      description = "Event Farm environment name"
    }
    "CLUSTER" = {
      value       = var.cluster_name
      type        = "SecureString"
      description = "Cluster name"
    }
    "DOMAIN" = {
      value       = var.domain
      type        = "SecureString"
      description = "Main domain"
    }
    "API_DOMAIN" = {
      value       = var.api_domain
      type        = "SecureString"
      description = "API domain"
    }
    "LOGIN_DOMAIN" = {
      value       = var.login_domain
      type        = "SecureString"
      description = "Login domain"
    }
    "BASE_DOMAIN" = {
      value       = var.base_domain
      type        = "SecureString"
      description = "Base domain"
    }
    "SCHEME" = {
      value       = "http"
      type        = "SecureString"
      description = "URL scheme (http/https)"
    }
    "SERVICE_DISCOVERY_NAMESPACE" = {
      value       = var.enable_service_discovery ? var.service_discovery_namespace : ""
      type        = "SecureString"
      description = "Service discovery namespace"
    }
    "APP_ENV" = {
      value       = var.app_env
      type        = "SecureString"
      description = "Application environment (production, staging, etc.)"
    }

    # Database configuration
    "MYSQL_HOST" = {
      value       = var.database_host
      type        = "SecureString"
      description = "MySQL database host"
    }
    "MYSQL_USER" = {
      value       = var.database_user
      type        = "SecureString"
      description = "MySQL database user"
    }
    "MYSQL_PASSWORD" = {
      value       = var.database_password
      type        = "SecureString"
      description = "MySQL database password (encrypted)"
    }
    "MYSQL_DATABASE" = {
      value       = var.database_name
      type        = "SecureString"
      description = "MySQL database name"
    }

    # Twilio configuration
    "TWILIO_SID" = var.twilio_sid != "" ? {
      value       = var.twilio_sid
      type        = "SecureString"
      description = "Twilio Account SID (encrypted)"
    } : null
    "TWILIO_TOKEN" = var.twilio_token != "" ? {
      value       = var.twilio_token
      type        = "SecureString"
      description = "Twilio Auth Token (encrypted)"
    } : null
    "TWILIO_MSG_SERVICE_SID" = var.twilio_msg_service_sid != "" ? {
      value       = var.twilio_msg_service_sid
      type        = "SecureString"
      description = "Twilio Messaging Service SID (encrypted)"
    } : null
    "TWILIO_MSG_STATUS_CALLBACK_URL" = var.twilio_msg_status_callback_url != "" ? {
      value       = var.twilio_msg_status_callback_url
      type        = "SecureString"
      description = "Twilio message status callback URL"
    } : null

    # Worker service configuration
    "GEARMAN_HOST" = {
      value       = var.enable_service_discovery ? "gearman-server.${var.service_discovery_namespace}" : "gearman-server"
      type        = "SecureString"
      description = "Gearman server hostname"
    }
    "GEARMAN_PORT" = {
      value       = "4730"
      type        = "SecureString"
      description = "Gearman server port"
    }

    # URL to PNG service configuration
    "NODE_ENV" = {
      value       = "production"
      type        = "SecureString"
      description = "Node.js environment"
    }
    "STORAGE_PROVIDER" = {
      value       = "s3"
      type        = "SecureString"
      description = "Storage provider (s3, local, etc.)"
    }
    "AWS_REGION" = {
      value       = var.aws_region
      type        = "SecureString"
      description = "AWS region for S3 storage"
    }
    "PUPPETEER_WAIT_UNTIL" = {
      value       = "networkidle2"
      type        = "SecureString"
      description = "Puppeteer wait condition for page load"
    }

    # Application configuration
    "BASE_URI" = {
      value       = "${var.acm_certificate_arn != "" ? "https" : "http"}://${var.domain}"
      type        = "SecureString"
      description = "Base application URI"
    }
    "API2_BASE_URI" = {
      value       = "${var.acm_certificate_arn != "" ? "https" : "http"}://${var.domain}/api"
      type        = "SecureString"
      description = "API2 base URI"
    }
    "LOGIN_BASE_URI" = {
      value       = "${var.acm_certificate_arn != "" ? "https" : "http"}://${var.login_domain}"
      type        = "SecureString"
      description = "Login base URI"
    }
    "SCHEDULER_BASE_URI" = {
      value       = "http://scheduler.${var.enable_service_discovery ? var.service_discovery_namespace : "eventfarm.local"}:4000"
      type        = "SecureString"
      description = "Scheduler service base URI"
    }
    "GEARMAN_BASE_URI" = {
      value       = "http://gearman-server.${var.enable_service_discovery ? var.service_discovery_namespace : "eventfarm.local"}:4730"
      type        = "SecureString"
      description = "Gearman server base URI"
    }
    "DEBUG" = {
      value       = "0"
      type        = "SecureString"
      description = "Debug mode flag"
    }
    "APP_DEBUG" = {
      value       = "false"
      type        = "SecureString"
      description = "Application debug flag"
    }
    "SHOW_EXCEPTIONS" = {
      value       = "false"
      type        = "SecureString"
      description = "Show exceptions flag"
    }

    # MongoDB configuration (optional)
    "MONGO_HOST" = var.mongodb_host != "" ? {
      value       = var.mongodb_host
      type        = "SecureString"
      description = "MongoDB host"
    } : null
    "MONGO_USER" = var.mongodb_user != "" ? {
      value       = var.mongodb_user
      type        = "SecureString"
      description = "MongoDB user"
    } : null
    "MONGO_PASSWORD" = var.mongodb_password != "" ? {
      value       = var.mongodb_password
      type        = "SecureString"
      description = "MongoDB password"
    } : null
    "MONGO_DATABASE" = var.mongodb_database != "" ? {
      value       = var.mongodb_database
      type        = "SecureString"
      description = "MongoDB database name"
    } : null
    "MONGO_EMAIL_DATABASE" = var.mongodb_email_database != "" ? {
      value       = var.mongodb_email_database
      type        = "SecureString"
      description = "MongoDB email database name"
    } : null

    # Gearman server configuration
    "VERBOSE" = {
      value       = "INFO"
      type        = "SecureString"
      description = "Gearman server verbosity level"
    }

    # ========================================================================
    # ADD NEW ENVIRONMENT VARIABLES HERE
    # ========================================================================
    # Step 1: Add your parameter definition below
    # 
    # For sensitive data (passwords, tokens, API keys):
    # "NEW_API_KEY" = {
    #   value       = var.new_api_key
    #   type        = "SecureString"  # This encrypts the value
    #   description = "API key for new service"
    # }
    #
  }

  # ========================================================================
  # Service Parameter Mappings
  # ========================================================================
  # Step 2: Add parameter names to the services that need them
  # 
  # Example: If you added "NEW_API_KEY" above and the app service needs it:
  #   Add "NEW_API_KEY" to the app_parameter_keys list below
  #
  # Define which parameters each ECS service needs access to

  # App service - list all parameters it needs
  # If parameter doesn't exist in SSM, it will be automatically filtered out
  app_parameter_keys = [
    "EF_ENV",
    "CLUSTER",
    "DOMAIN",
    "API_DOMAIN",
    "LOGIN_DOMAIN",
    "BASE_DOMAIN",
    "SCHEME",
    "SERVICE_DISCOVERY_NAMESPACE",
    "APP_ENV",
    "MYSQL_HOST",
    "MYSQL_USER",
    "MYSQL_PASSWORD",
    "MYSQL_DATABASE",
    "BASE_URI",
    "API2_BASE_URI",
    "LOGIN_BASE_URI",
    "SCHEDULER_BASE_URI",
    "GEARMAN_BASE_URI",
    "DEBUG",
    "APP_DEBUG",
    "SHOW_EXCEPTIONS",
    "TWILIO_SID",
    "TWILIO_TOKEN",
    "TWILIO_MSG_SERVICE_SID",
    "TWILIO_MSG_STATUS_CALLBACK_URL",
    "MONGO_HOST",
    "MONGO_USER",
    "MONGO_PASSWORD",
    "MONGO_DATABASE",
    "MONGO_EMAIL_DATABASE",
  ]

  # API2 service - list all parameters it needs
  api2_parameter_keys = [
    "EF_ENV",
    "CLUSTER",
    "API_DOMAIN",
    "APP_ENV",
    "MYSQL_HOST",
    "MYSQL_USER",
    "MYSQL_PASSWORD",
    "MYSQL_DATABASE",
    "BASE_URI",
    "API2_BASE_URI",
    "DEBUG",
    "APP_DEBUG",
    "SHOW_EXCEPTIONS",
    "TWILIO_SID",
    "TWILIO_TOKEN",
    "TWILIO_MSG_SERVICE_SID",
    "TWILIO_MSG_STATUS_CALLBACK_URL",
  ]

  worker_parameter_keys = [
    "EF_ENV",
    "CLUSTER",
    "GEARMAN_HOST",
    "GEARMAN_PORT",
  ]

  canvas_parameter_keys = [
    "EF_ENV",
    "CLUSTER",
  ]

  urltopng_parameter_keys = [
    "NODE_ENV",
    "STORAGE_PROVIDER",
    "AWS_REGION",
    "PUPPETEER_WAIT_UNTIL",
  ]

  scheduler_parameter_keys = [
    "EF_ENV",
    "CLUSTER",
  ]

  gearman_parameter_keys = [
    "VERBOSE",
  ]

  # SSM parameter path prefix - all params go under /{cluster}/{environment}/
  parameter_prefix = "/${var.cluster_name}/${var.environment}"
}

# Create SSM parameters - using standard AWS provider resources
# Need to extract keys separately because Terraform doesn't like sensitive values in for_each
locals {
  ssm_parameter_keys = nonsensitive(toset([
    for k, v in local.ssm_parameters : k
    if v != null
  ]))
}

# Create the SSM parameters
resource "aws_ssm_parameter" "parameter" {
  for_each = local.ssm_parameter_keys

  name  = "${local.parameter_prefix}/${each.key}"
  type  = local.ssm_parameters[each.key].type
  value = local.ssm_parameters[each.key].value

  description = try(local.ssm_parameters[each.key].description, "Environment variable for ${var.cluster_name} cluster")

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

# Build the secrets arrays that ECS task definitions need
# ECS expects secrets in a specific format: { name = "VAR_NAME", valueFrom = "ssm:/path/to/param" }
locals {
  # Map parameter names to their full SSM paths
  parameter_names = {
    for k, v in aws_ssm_parameter.parameter : k => v.name
  }

  # Build secrets arrays - automatically filter out parameters that don't exist
  # If a parameter is null in ssm_parameters, it won't be in parameter_names, so it's skipped
  app_secrets = [
    for key in local.app_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
    if contains(keys(local.parameter_names), key)
  ]

  api2_secrets = [
    for key in local.api2_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
    if contains(keys(local.parameter_names), key)
  ]

  worker_secrets = [
    for key in local.worker_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
    if contains(keys(local.parameter_names), key)
  ]

  canvas_secrets = [
    for key in local.canvas_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
    if contains(keys(local.parameter_names), key)
  ]

  urltopng_secrets = [
    for key in local.urltopng_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
    if contains(keys(local.parameter_names), key)
  ]

  scheduler_secrets = [
    for key in local.scheduler_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
    if contains(keys(local.parameter_names), key)
  ]

  gearman_secrets = [
    for key in local.gearman_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
    if contains(keys(local.parameter_names), key)
  ]
}

