# SSM Parameter Store - environment variables and secrets placed here
#
# To add a new environment variable:
#   1. Add it to the ssm_parameters map below
#   2. Add the parameter name to the service's parameter_keys list (app_parameter_keys, etc.)
#   3. Run terraform plan/apply
#
# Parameter types:
#   - SecureString: passwords, tokens, API keys (encrypted at rest)
#   - String: URLs, hostnames, non-sensitive config
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
      type        = "String"
      description = "Event Farm environment name"
    }
    "CLUSTER" = {
      value       = var.cluster_name
      type        = "String"
      description = "Cluster name"
    }
    "DOMAIN" = {
      value       = var.domain
      type        = "String"
      description = "Main domain"
    }
    "API_DOMAIN" = {
      value       = var.api_domain
      type        = "String"
      description = "API domain"
    }
    "LOGIN_DOMAIN" = {
      value       = var.login_domain
      type        = "String"
      description = "Login domain"
    }
    "BASE_DOMAIN" = {
      value       = var.base_domain
      type        = "String"
      description = "Base domain"
    }
    "SCHEME" = {
      value       = "http"
      type        = "String"
      description = "URL scheme (http/https)"
    }
    "SERVICE_DISCOVERY_NAMESPACE" = {
      value       = var.enable_service_discovery ? var.service_discovery_namespace : ""
      type        = "String"
      description = "Service discovery namespace"
    }
    "APP_ENV" = {
      value       = var.app_env
      type        = "String"
      description = "Application environment (production, staging, etc.)"
    }

    # Database configuration
    "MYSQL_HOST" = {
      value       = var.database_host
      type        = "String"
      description = "MySQL database host"
    }
    "MYSQL_USER" = {
      value       = var.database_user
      type        = "String"
      description = "MySQL database user"
    }
    "MYSQL_PASSWORD" = {
      value       = var.database_password
      type        = "SecureString"
      description = "MySQL database password (encrypted)"
    }
    "MYSQL_DATABASE" = {
      value       = var.database_name
      type        = "String"
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
      type        = "String"
      description = "Twilio message status callback URL"
    } : null

    # Worker service configuration
    "GEARMAN_HOST" = {
      value       = var.enable_service_discovery ? "gearman-server.${var.service_discovery_namespace}" : "gearman-server"
      type        = "String"
      description = "Gearman server hostname"
    }
    "GEARMAN_PORT" = {
      value       = "4730"
      type        = "String"
      description = "Gearman server port"
    }

    # URL to PNG service configuration
    "NODE_ENV" = {
      value       = "production"
      type        = "String"
      description = "Node.js environment"
    }
    "STORAGE_PROVIDER" = {
      value       = "s3"
      type        = "String"
      description = "Storage provider (s3, local, etc.)"
    }
    "AWS_REGION" = {
      value       = var.aws_region
      type        = "String"
      description = "AWS region for S3 storage"
    }
    "PUPPETEER_WAIT_UNTIL" = {
      value       = "networkidle2"
      type        = "String"
      description = "Puppeteer wait condition for page load"
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

  app_parameter_keys = concat(
    [
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
    ],
    var.twilio_sid != "" ? [
      "TWILIO_SID",
      "TWILIO_TOKEN",
      "TWILIO_MSG_SERVICE_SID",
      "TWILIO_MSG_STATUS_CALLBACK_URL",
    ] : []
  )

  api2_parameter_keys = concat(
    [
      "EF_ENV",
      "CLUSTER",
      "API_DOMAIN",
      "APP_ENV",
      "MYSQL_HOST",
      "MYSQL_USER",
      "MYSQL_PASSWORD",
      "MYSQL_DATABASE",
    ],
    var.twilio_sid != "" ? [
      "TWILIO_SID",
      "TWILIO_TOKEN",
      "TWILIO_MSG_SERVICE_SID",
      "TWILIO_MSG_STATUS_CALLBACK_URL",
    ] : []
  )

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

  app_secrets = [
    for key in local.app_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  api2_secrets = [
    for key in local.api2_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  worker_secrets = [
    for key in local.worker_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  canvas_secrets = [
    for key in local.canvas_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  urltopng_secrets = [
    for key in local.urltopng_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]

  scheduler_secrets = [
    for key in local.scheduler_parameter_keys : {
      name      = key
      valueFrom = local.parameter_names[key]
    }
  ]
}

