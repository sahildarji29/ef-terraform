# ============================================================================
# SSM Parameter Store - All Environment Variables & Secrets
# ============================================================================
# This is the SINGLE SOURCE OF TRUTH for all environment variables.
#
# STANDARD APPROACH FOR SECRETS:
#   Option 1 (RECOMMENDED): Create secrets manually in AWS Console/CLI, then reference by ARN
#   Option 2: Store in terraform.tfvars (gitignored) - only for initial setup
#
# HOW TO ADD NEW ENVIRONMENT VARIABLES:
#   1. Add parameter definition in ssm_parameters map below (around line 20)
#   2. Add parameter name to service's parameter_keys list (around line 160)
#   3. Run: terraform plan && terraform apply
#
# PARAMETER TYPES:
#   - SecureString: For passwords, tokens, API keys (encrypted)
#   - String: For URLs, hostnames, non-sensitive config
#
# EXAMPLE - Adding STRIPE_API_KEY for app service:
#   1. In ssm_parameters: "STRIPE_API_KEY" = { value = var.stripe_api_key, type = "SecureString", description = "..." }
#   2. In app_parameter_keys: Add "STRIPE_API_KEY" to the list
#   3. Done! Parameter will be available as env var STRIPE_API_KEY in app container
# ============================================================================

locals {
  # SSM Parameters - Simple naming without categories
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
    # For non-sensitive config (URLs, hostnames, etc.):
    # "NEW_API_URL" = {
    #   value       = var.new_api_url
    #   type        = "String"
    #   description = "API endpoint URL"
    # }
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

  # Parameter prefix for SSM paths
  parameter_prefix = "/eventfarm/${var.environment}/${var.cluster_name}"
}

# SSM Parameters - Direct resource definitions using standard AWS provider
# Create a set of non-null parameter keys (keys are not sensitive, only values are)
locals {
  ssm_parameter_keys = nonsensitive(toset([
    for k, v in local.ssm_parameters : k
    if v != null
  ]))
}

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

# ECS Secrets Arrays - Built from SSM parameters
locals {
  # Map of parameter names to their full SSM paths (for ECS secrets)
  parameter_names = {
    for k, v in aws_ssm_parameter.parameter : k => v.name
  }

  # ========================================================================
  # ECS Secrets Arrays
  # ========================================================================
  # Convert parameter names to ECS secrets format for task definitions
  # Format: { name = "VAR_NAME", valueFrom = "arn:aws:ssm:region:account:parameter/..." }

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

