# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Network Module - Uses existing VPC
module "network" {
  source = "../../modules/network"

  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  cluster_name      = var.cluster_name

  tags = var.tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  vpc_id                      = module.network.vpc_id
  cluster_name                = var.cluster_name
  environment                 = var.environment
  allowed_cidr_blocks        = var.allowed_cidr_blocks
  database_security_group_id  = var.database_security_group_id
  mongodb_security_group_id   = var.mongodb_security_group_id

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

  cluster_name                  = var.cluster_name
  enable_container_insights    = true
  enable_service_discovery      = var.enable_service_discovery
  service_discovery_namespace   = var.service_discovery_namespace
  vpc_id                        = module.network.vpc_id
  log_group_name                = module.monitoring.log_groups["app"].name

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

  cluster_name              = var.cluster_name
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.public_subnet_ids
  security_group_id         = module.security.alb_security_group_id
  enable_deletion_protection = var.environment == "prod"
  # certificate_arn            = local.certificate_arn  # COMMENTED OUT (no domain yet)
  certificate_arn            = ""  # Empty for now
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

  family            = "${var.cluster_name}-app"
  cluster_name      = var.cluster_name
  cpu               = var.app_cpu
  memory            = var.app_memory
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn     = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "app"
    image     = var.app_image
    essential = true
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    environment = [
      { name = "EF_ENV", value = var.environment },
      { name = "CLUSTER", value = var.cluster_name },
      { name = "DOMAIN", value = var.domain },
      { name = "API_DOMAIN", value = var.api_domain },
      { name = "LOGIN_DOMAIN", value = var.login_domain },
      { name = "BASE_DOMAIN", value = var.base_domain },
    ]
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

  family            = "${var.cluster_name}-api2"
  cluster_name      = var.cluster_name
  cpu               = var.api2_cpu
  memory            = var.api2_memory
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn     = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "api2"
    image     = var.api2_image
    essential = true
    environment = [
      { name = "EF_ENV", value = var.environment },
      { name = "CLUSTER", value = var.cluster_name },
      { name = "API_DOMAIN", value = var.api_domain },
    ]
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

  family            = "${var.cluster_name}-process-job-worker"
  cluster_name      = var.cluster_name
  cpu               = var.worker_cpu
  memory            = var.worker_memory
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn     = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "process-job-worker"
    image     = var.process_job_worker_image
    essential = true
    command = [
      "-f", "process-job",
      "--",
      "xargs",
      "php",
      "/Domain/src/Infrastructure/Console/process-job.php"
    ]
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

  family            = "${var.cluster_name}-canvas"
  cluster_name      = var.cluster_name
  cpu               = 512
  memory            = 1024
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn     = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "canvas"
    image     = var.canvas_image
    essential = true
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
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

  family            = "${var.cluster_name}-urltopng"
  cluster_name      = var.cluster_name
  cpu               = 1024
  memory            = 2048
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn     = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "urltopng"
    image     = var.urltopng_image
    essential = true
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
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
  }])

  tags = var.tags
}

# Gearman Server Task
module "task_gearman" {
  source = "../../modules/ecs/task"

  family            = "${var.cluster_name}-gearman-server"
  cluster_name      = var.cluster_name
  cpu               = 512
  memory            = 1024
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn     = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "gearman-server"
    image     = var.gearman_server_image
    essential = true
    portMappings = [{
      containerPort = 4730
      protocol      = "tcp"
    }]
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

  family            = "${var.cluster_name}-scheduler"
  cluster_name      = var.cluster_name
  cpu               = 512
  memory            = 1024
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn     = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name      = "scheduler"
    image     = var.scheduler_image
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

  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = var.cluster_name
  service_name       = "${var.cluster_name}-app"
  task_definition_arn = module.task_app.task_definition_arn
  desired_count      = var.app_scale
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.app_security_group_id]
  assign_public_ip   = false
  target_group_arn   = module.alb.target_group_app_arn
  container_name     = "app"
  container_port     = 80
  enable_auto_scaling = var.enable_auto_scaling
  min_capacity       = var.min_capacity["app"]
  max_capacity       = var.max_capacity["app"]

  depends_on = [
    module.alb
  ]

  tags = var.tags
}

# API2 Service
module "service_api2" {
  source = "../../modules/ecs/service"

  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = var.cluster_name
  service_name       = "${var.cluster_name}-api2"
  task_definition_arn = module.task_api2.task_definition_arn
  desired_count      = var.api2_scale
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.api2_security_group_id]
  assign_public_ip   = false
  enable_service_discovery = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name = "api2"
  enable_auto_scaling = var.enable_auto_scaling
  min_capacity       = var.min_capacity["api2"]
  max_capacity       = var.max_capacity["api2"]

  tags = var.tags
}

# Process Job Worker Service
module "service_worker" {
  source = "../../modules/ecs/service"

  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = var.cluster_name
  service_name       = "${var.cluster_name}-process-job-worker"
  task_definition_arn = module.task_worker.task_definition_arn
  desired_count      = var.worker_scale
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.worker_security_group_id]
  assign_public_ip   = false
  enable_service_discovery = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name = "process-job-worker"
  enable_auto_scaling = var.enable_auto_scaling
  min_capacity       = var.min_capacity["worker"]
  max_capacity       = var.max_capacity["worker"]

  tags = var.tags
}

# Canvas Service
module "service_canvas" {
  source = "../../modules/ecs/service"

  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = var.cluster_name
  service_name       = "${var.cluster_name}-canvas"
  task_definition_arn = module.task_canvas.task_definition_arn
  desired_count      = 1
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.canvas_security_group_id]
  assign_public_ip   = false
  enable_service_discovery = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name = "canvas"

  tags = var.tags
}

# URL to PNG Service
module "service_urltopng" {
  source = "../../modules/ecs/service"

  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = var.cluster_name
  service_name       = "${var.cluster_name}-urltopng"
  task_definition_arn = module.task_urltopng.task_definition_arn
  desired_count      = var.urltopng_scale
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.urltopng_security_group_id]
  assign_public_ip   = false
  enable_service_discovery = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name = "urltopng"

  tags = var.tags
}

# Gearman Server Service
module "service_gearman" {
  source = "../../modules/ecs/service"

  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = var.cluster_name
  service_name       = "${var.cluster_name}-gearman-server"
  task_definition_arn = module.task_gearman.task_definition_arn
  desired_count      = 1
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.gearman_security_group_id]
  assign_public_ip   = false
  enable_service_discovery = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name = "gearman-server"

  tags = var.tags
}

# Scheduler Service
module "service_scheduler" {
  source = "../../modules/ecs/service"

  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = var.cluster_name
  service_name       = "${var.cluster_name}-scheduler"
  task_definition_arn = module.task_scheduler.task_definition_arn
  desired_count      = 1
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.scheduler_security_group_id]
  assign_public_ip   = false
  enable_service_discovery = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name = "scheduler"

  tags = var.tags
}

