# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Docker Hub Credentials Secret
# Store Docker Hub credentials in Secrets Manager for ECS to pull private images
resource "aws_secretsmanager_secret" "dockerhub" {
  count = var.dockerhub_secret_arn == "" && var.dockerhub_username != "" ? 1 : 0

  name        = "${var.cluster_name}-dockerhub-credentials"
  description = "Docker Hub credentials for pulling private images"

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-dockerhub-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "dockerhub" {
  count = var.dockerhub_secret_arn == "" && var.dockerhub_username != "" ? 1 : 0

  secret_id = aws_secretsmanager_secret.dockerhub[0].id
  secret_string = jsonencode({
    username = var.dockerhub_username
    password = var.dockerhub_password
  })
}

locals {
  dockerhub_secret_arn = var.dockerhub_secret_arn != "" ? var.dockerhub_secret_arn : (var.dockerhub_username != "" ? aws_secretsmanager_secret.dockerhub[0].arn : "")

  # ECR Image URIs - Use ECR if use_ecr is true, otherwise use Docker Hub images
  account_id   = data.aws_caller_identity.current.account_id
  ecr_registry = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

  app_image_uri       = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-app:${var.app_image_tag}" : var.app_image
  api2_image_uri      = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-api2:${var.api2_image_tag}" : var.api2_image
  canvas_image_uri    = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-canvas:${var.canvas_image_tag}" : var.canvas_image
  worker_image_uri    = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-process-job-worker:${var.process_job_worker_image_tag}" : var.process_job_worker_image
  urltopng_image_uri  = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-urltopng:${var.urltopng_image_tag}" : var.urltopng_image
  gearman_image_uri   = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-gearmand:${var.gearman_server_image_tag}" : var.gearman_server_image
  scheduler_image_uri = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-scheduler:${var.scheduler_image_tag}" : var.scheduler_image
}

# Network Module - Uses existing VPC
module "network" {
  source = "../../modules/network"

  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  cluster_name       = var.cluster_name

  tags = var.tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  vpc_id                     = module.network.vpc_id
  cluster_name               = var.cluster_name
  environment                = var.environment
  allowed_cidr_blocks        = var.allowed_cidr_blocks
  database_security_group_id = var.database_security_group_id
  mongodb_security_group_id  = var.mongodb_security_group_id

  tags = var.tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  cluster_name = var.cluster_name

  tags = var.tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  cluster_name       = var.cluster_name
  log_retention_days = var.log_retention_days

  tags = var.tags
}

# ECS Cluster Module
module "ecs_cluster" {
  source = "../../modules/ecs/cluster"

  cluster_name                = var.cluster_name
  enable_container_insights   = true
  enable_service_discovery    = var.enable_service_discovery
  service_discovery_namespace = var.service_discovery_namespace
  vpc_id                      = module.network.vpc_id
  log_group_name              = module.monitoring.log_groups["app"].name

  tags = var.tags
}

# ACM Certificate - COMMENTED OUT (no domain yet)
# resource "aws_acm_certificate" "main" {
#   count            = var.acm_certificate_arn == "" ? 1 : 0
#   domain_name      = var.domain
#   validation_method = "DNS"
#
#   subject_alternative_names = [
#     var.api_domain,
#     var.login_domain,
#     var.base_domain,
#     "*.${var.base_domain}"
#   ]
#
#   lifecycle {
#     create_before_destroy = true
#   }
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.cluster_name}-cert"
#     }
#   )
# }

# locals {
#   certificate_arn = var.acm_certificate_arn != "" ? var.acm_certificate_arn : aws_acm_certificate.main[0].arn
# }

# ALB Module
module "alb" {
  source = "../../modules/ecs/alb"

  cluster_name               = var.cluster_name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.public_subnet_ids
  security_group_id          = module.security.alb_security_group_id
  enable_deletion_protection = false
  certificate_arn            = var.acm_certificate_arn
  enable_https               = var.acm_certificate_arn != "" ? true : false
  redirect_http_to_https     = var.acm_certificate_arn != "" ? true : false
  domain                     = var.domain
  api_domain                 = var.api_domain
  login_domain               = var.login_domain
  base_domain                = var.base_domain

  # depends_on = [
  #   aws_acm_certificate.main
  # ]  # COMMENTED OUT (no certificate)

  tags = var.tags
}

# Task Definitions
# App Task
module "task_app" {
  source = "../../modules/ecs/task"

  family             = "${var.cluster_name}-app"
  cluster_name       = var.cluster_name
  cpu                = var.app_cpu
  memory             = var.app_memory
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "app"
    image     = local.app_image_uri
    essential = true
    # Override entrypoint to use MYSQL_HOST env var instead of hardcoded "mysql" hostname
    # The original run.sh checks "mysql" hostname, but ECS doesn't have that DNS entry
    # We use the MYSQL_HOST environment variable that's already set below
    entryPoint = ["/bin/bash", "-c"]
    command = [
      "cd /var/www/ && dockerize -template /etc/nginx/conf.d/api.tmpl:/etc/nginx/conf.d/api.conf -template /etc/nginx/conf.d/auth.tmpl:/etc/nginx/conf.d/auth.conf -template /etc/nginx/conf.d/core.tmpl:/etc/nginx/conf.d/core.conf -template /var/www/Core/webroot/js/config.js.tmpl:/var/www/Core/webroot/js/config.js && if [ -n \"$${SERVICE_DISCOVERY_NAMESPACE}\" ]; then sed -i \"s|http://api2|http://api2.$${SERVICE_DISCOVERY_NAMESPACE}|g\" /etc/nginx/conf.d/core.conf && sed -i \"s|http://canvas|http://canvas.$${SERVICE_DISCOVERY_NAMESPACE}|g\" /etc/nginx/conf.d/core.conf && sed -i \"s|http://urltopng:3000|http://urltopng.$${SERVICE_DISCOVERY_NAMESPACE}:3000|g\" /etc/nginx/conf.d/core.conf && sed -i \"s|http://api/|http://api2.$${SERVICE_DISCOVERY_NAMESPACE}/|g\" /etc/nginx/conf.d/core.conf; fi && until nc -z \"$${MYSQL_HOST}\" 3306; do echo \"$$(date) - waiting for mysql at $${MYSQL_HOST}...\"; sleep 1; done && /usr/bin/supervisord -n -c /etc/supervisord.conf"
    ]
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    # ECR uses IAM roles (no credentials needed), Docker Hub uses Secrets Manager
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    environment = concat([
      { name = "EF_ENV", value = var.environment },
      { name = "CLUSTER", value = var.cluster_name },
      { name = "DOMAIN", value = var.domain },
      { name = "API_DOMAIN", value = var.api_domain },
      { name = "LOGIN_DOMAIN", value = var.login_domain },
      { name = "BASE_DOMAIN", value = var.base_domain },
      { name = "SCHEME", value = "http" },
      { name = "SERVICE_DISCOVERY_NAMESPACE", value = var.enable_service_discovery ? var.service_discovery_namespace : "" },
      { name = "MYSQL_HOST", value = var.database_host },
      { name = "MYSQL_USER", value = var.database_user },
      { name = "MYSQL_PASSWORD", value = var.database_password },
      { name = "MYSQL_DATABASE", value = var.database_name },
      { name = "APP_ENV", value = var.app_env },
      ], var.twilio_sid != "" ? [
      { name = "TWILIO_SID", value = var.twilio_sid },
      { name = "TWILIO_TOKEN", value = var.twilio_token },
      { name = "TWILIO_MSG_SERVICE_SID", value = var.twilio_msg_service_sid },
      { name = "TWILIO_MSG_STATUS_CALLBACK_URL", value = var.twilio_msg_status_callback_url },
    ] : [])
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.monitoring.log_groups["app"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "app"
      }
    }
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:80/ || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = var.tags
}

# API2 Task
module "task_api2" {
  source = "../../modules/ecs/task"

  family             = "${var.cluster_name}-api2"
  cluster_name       = var.cluster_name
  cpu                = var.api2_cpu
  memory             = var.api2_memory
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "api2"
    image     = local.api2_image_uri
    essential = true
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    # ECR uses IAM roles (no credentials needed), Docker Hub uses Secrets Manager
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    environment = concat([
      { name = "EF_ENV", value = var.environment },
      { name = "CLUSTER", value = var.cluster_name },
      { name = "API_DOMAIN", value = var.api_domain },
      { name = "MYSQL_HOST", value = var.database_host },
      { name = "MYSQL_USER", value = var.database_user },
      { name = "MYSQL_PASSWORD", value = var.database_password },
      { name = "MYSQL_DATABASE", value = var.database_name },
      { name = "APP_ENV", value = var.app_env },
      ], var.twilio_sid != "" ? [
      { name = "TWILIO_SID", value = var.twilio_sid },
      { name = "TWILIO_TOKEN", value = var.twilio_token },
      { name = "TWILIO_MSG_SERVICE_SID", value = var.twilio_msg_service_sid },
      { name = "TWILIO_MSG_STATUS_CALLBACK_URL", value = var.twilio_msg_status_callback_url },
    ] : [])
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.monitoring.log_groups["api2"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "api2"
      }
    }
    healthCheck = {
      command     = ["CMD-SHELL", "php -r 'exit(0);' || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = var.tags
}

# Process Job Worker Task
module "task_worker" {
  source = "../../modules/ecs/task"

  family             = "${var.cluster_name}-process-job-worker"
  cluster_name       = var.cluster_name
  cpu                = var.worker_cpu
  memory             = var.worker_memory
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "process-job-worker"
    image     = local.worker_image_uri
    essential = true
    command = [
      "-f", "process-job",
      "--",
      "xargs",
      "php",
      "/Domain/src/Infrastructure/Console/process-job.php"
    ]
    # ECR uses IAM roles (no credentials needed), Docker Hub uses Secrets Manager
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    environment = [
      { name = "EF_ENV", value = var.environment },
      { name = "CLUSTER", value = var.cluster_name },
      { name = "GEARMAN_HOST", value = var.enable_service_discovery ? "gearman-server.${var.service_discovery_namespace}" : "gearman-server" },
      { name = "GEARMAN_PORT", value = "4730" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.monitoring.log_groups["process-job-worker"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "worker"
      }
    }
  }])

  tags = var.tags
}

# Canvas Task
module "task_canvas" {
  source = "../../modules/ecs/task"

  family             = "${var.cluster_name}-canvas"
  cluster_name       = var.cluster_name
  cpu                = 512
  memory             = 1024
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "canvas"
    image     = local.canvas_image_uri
    essential = true
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    # ECR uses IAM roles (no credentials needed), Docker Hub uses Secrets Manager
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    environment = [
      { name = "EF_ENV", value = var.environment },
      { name = "CLUSTER", value = var.cluster_name },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.monitoring.log_groups["canvas"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "canvas"
      }
    }
  }])

  tags = var.tags
}

# URL to PNG Task
module "task_urltopng" {
  source = "../../modules/ecs/task"

  family             = "${var.cluster_name}-urltopng"
  cluster_name       = var.cluster_name
  cpu                = 1024
  memory             = 2048
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "urltopng"
    image     = local.urltopng_image_uri
    essential = true
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
    # ECR uses IAM roles (no credentials needed), Docker Hub uses Secrets Manager
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    environment = [
      { name = "NODE_ENV", value = "production" },
      { name = "STORAGE_PROVIDER", value = "s3" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "PUPPETEER_WAIT_UNTIL", value = "networkidle2" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.monitoring.log_groups["urltopng"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "urltopng"
      }
    }
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:3000/ || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = var.tags
}

# Gearman Server Task
module "task_gearman" {
  source = "../../modules/ecs/task"

  family             = "${var.cluster_name}-gearman-server"
  cluster_name       = var.cluster_name
  cpu                = 512
  memory             = 1024
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "gearman-server"
    image     = local.gearman_image_uri
    essential = true
    portMappings = [{
      containerPort = 4730
      protocol      = "tcp"
    }]
    # ECR uses IAM roles (no credentials needed), Docker Hub uses Secrets Manager
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    environment = [
      { name = "VERBOSE", value = "INFO" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.monitoring.log_groups["gearman-server"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "gearman"
      }
    }
  }])

  tags = var.tags
}

# Scheduler Task
module "task_scheduler" {
  source = "../../modules/ecs/task"

  family             = "${var.cluster_name}-scheduler"
  cluster_name       = var.cluster_name
  cpu                = 512
  memory             = 1024
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "scheduler"
    image     = local.scheduler_image_uri
    essential = true
    command = [
      "kala",
      "serve",
      "-p", "4000",
      "-v",
      "--jobdb=mariadb",
      "--jobdb-address=tcp(${var.database_host})/${var.database_name}",
      "--jobdb-username=${var.database_user}",
      "--jobdb-password=${var.database_password}",
      "--persist-every=60"
    ]
    portMappings = [{
      containerPort = 4000
      protocol      = "tcp"
    }]
    # ECR uses IAM roles (no credentials needed), Docker Hub uses Secrets Manager
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    environment = [
      { name = "EF_ENV", value = var.environment },
      { name = "CLUSTER", value = var.cluster_name },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.monitoring.log_groups["scheduler"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "scheduler"
      }
    }
  }])

  tags = var.tags
}

# ECS Services
# App Service
module "service_app" {
  source = "../../modules/ecs/service"

  cluster_id          = module.ecs_cluster.cluster_id
  cluster_name        = var.cluster_name
  service_name        = "${var.cluster_name}-app"
  task_definition_arn = module.task_app.task_definition_arn
  desired_count       = var.app_scale
  subnet_ids          = module.network.private_subnet_ids
  security_group_ids  = [module.security.app_security_group_id]
  assign_public_ip    = false
  target_group_arn    = module.alb.target_group_app_arn
  container_name      = "app"
  container_port      = 80
  enable_auto_scaling = var.enable_auto_scaling
  min_capacity        = var.min_capacity["app"]
  max_capacity        = var.max_capacity["app"]

  depends_on = [
    module.alb
  ]

  tags = var.tags
}

# API2 Service
module "service_api2" {
  source = "../../modules/ecs/service"

  cluster_id                     = module.ecs_cluster.cluster_id
  cluster_name                   = var.cluster_name
  service_name                   = "${var.cluster_name}-api2"
  task_definition_arn            = module.task_api2.task_definition_arn
  desired_count                  = var.api2_scale
  subnet_ids                     = module.network.private_subnet_ids
  security_group_ids             = [module.security.api2_security_group_id]
  assign_public_ip               = false
  target_group_arn               = module.alb.target_group_api2_arn
  container_name                 = "api2"
  container_port                 = 80
  enable_service_discovery       = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name         = "api2"
  enable_auto_scaling            = var.enable_auto_scaling
  min_capacity                   = var.min_capacity["api2"]
  max_capacity                   = var.max_capacity["api2"]

  depends_on = [
    module.alb
  ]

  tags = var.tags
}

# Process Job Worker Service
module "service_worker" {
  source = "../../modules/ecs/service"

  cluster_id                     = module.ecs_cluster.cluster_id
  cluster_name                   = var.cluster_name
  service_name                   = "${var.cluster_name}-process-job-worker"
  task_definition_arn            = module.task_worker.task_definition_arn
  desired_count                  = var.worker_scale
  subnet_ids                     = module.network.private_subnet_ids
  security_group_ids             = [module.security.worker_security_group_id]
  assign_public_ip               = false
  enable_service_discovery       = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name         = "process-job-worker"
  enable_auto_scaling            = var.enable_auto_scaling
  min_capacity                   = var.min_capacity["worker"]
  max_capacity                   = var.max_capacity["worker"]

  tags = var.tags
}

# Canvas Service
module "service_canvas" {
  source = "../../modules/ecs/service"

  cluster_id                     = module.ecs_cluster.cluster_id
  cluster_name                   = var.cluster_name
  service_name                   = "${var.cluster_name}-canvas"
  task_definition_arn            = module.task_canvas.task_definition_arn
  desired_count                  = 1
  subnet_ids                     = module.network.private_subnet_ids
  security_group_ids             = [module.security.canvas_security_group_id]
  assign_public_ip               = false
  target_group_arn               = module.alb.target_group_canvas_arn
  container_name                 = "canvas"
  container_port                 = 80
  enable_service_discovery       = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name         = "canvas"

  depends_on = [
    module.alb
  ]

  tags = var.tags
}

# URL to PNG Service
module "service_urltopng" {
  source = "../../modules/ecs/service"

  cluster_id                     = module.ecs_cluster.cluster_id
  cluster_name                   = var.cluster_name
  service_name                   = "${var.cluster_name}-urltopng"
  task_definition_arn            = module.task_urltopng.task_definition_arn
  desired_count                  = var.urltopng_scale
  subnet_ids                     = module.network.private_subnet_ids
  security_group_ids             = [module.security.urltopng_security_group_id]
  assign_public_ip               = false
  target_group_arn               = module.alb.target_group_urltopng_arn
  container_name                 = "urltopng"
  container_port                 = 3000
  enable_service_discovery       = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name         = "urltopng"

  depends_on = [
    module.alb
  ]

  tags = var.tags
}

# Gearman Server Service
module "service_gearman" {
  source = "../../modules/ecs/service"

  cluster_id                     = module.ecs_cluster.cluster_id
  cluster_name                   = var.cluster_name
  service_name                   = "${var.cluster_name}-gearman-server"
  task_definition_arn            = module.task_gearman.task_definition_arn
  desired_count                  = 1
  subnet_ids                     = module.network.private_subnet_ids
  security_group_ids             = [module.security.gearman_security_group_id]
  assign_public_ip               = false
  enable_service_discovery       = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name         = "gearman-server"

  tags = var.tags
}

# Scheduler Service
module "service_scheduler" {
  source = "../../modules/ecs/service"

  cluster_id                     = module.ecs_cluster.cluster_id
  cluster_name                   = var.cluster_name
  service_name                   = "${var.cluster_name}-scheduler"
  task_definition_arn            = module.task_scheduler.task_definition_arn
  desired_count                  = 1
  subnet_ids                     = module.network.private_subnet_ids
  security_group_ids             = [module.security.scheduler_security_group_id]
  assign_public_ip               = false
  enable_service_discovery       = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name         = "scheduler"

  tags = var.tags
}

