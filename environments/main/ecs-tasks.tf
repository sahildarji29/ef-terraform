module "task_app" {
  source = "../../modules/ecs/task"

  family             = "${var.cluster_name}-app"
  cluster_name       = var.cluster_name
  cpu                = var.app_cpu
  memory             = var.app_memory
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  container_definitions = jsonencode([{
    name       = "app"
    image      = local.app_image_uri
    essential  = true
    entryPoint = ["/bin/bash", "-c"]
    command = [
      "cd /var/www/ && dockerize -template /etc/nginx/conf.d/api.tmpl:/etc/nginx/conf.d/api.conf -template /etc/nginx/conf.d/auth.tmpl:/etc/nginx/conf.d/auth.conf -template /etc/nginx/conf.d/core.tmpl:/etc/nginx/conf.d/core.conf -template /var/www/Core/webroot/js/config.js.tmpl:/var/www/Core/webroot/js/config.js && if [ -n \"$${SERVICE_DISCOVERY_NAMESPACE}\" ]; then sed -i \"s|http://api2|http://api2.$${SERVICE_DISCOVERY_NAMESPACE}|g\" /etc/nginx/conf.d/core.conf && sed -i \"s|http://canvas|http://canvas.$${SERVICE_DISCOVERY_NAMESPACE}|g\" /etc/nginx/conf.d/core.conf && sed -i \"s|http://urltopng:3000|http://urltopng.$${SERVICE_DISCOVERY_NAMESPACE}:3000|g\" /etc/nginx/conf.d/core.conf && sed -i \"s|http://api/|http://api2.$${SERVICE_DISCOVERY_NAMESPACE}/|g\" /etc/nginx/conf.d/core.conf; fi && until nc -z \"$${MYSQL_HOST}\" 3306; do echo \"$$(date) - waiting for mysql at $${MYSQL_HOST}...\"; sleep 1; done && /usr/bin/supervisord -n -c /etc/supervisord.conf"
    ]
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    # All environment variables come from SSM Parameter Store
    environment = []
    # All secrets come from SSM Parameter Store (SecureString for sensitive data)
    secrets = local.app_secrets
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.monitoring.log_groups["app"].name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "app"
      }
    }
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:80/favicon.ico || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 90
    }
  }])

  tags = var.tags
}

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
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    # All environment variables come from SSM Parameter Store
    environment = []
    # All secrets come from SSM Parameter Store (SecureString for sensitive data)
    secrets = local.api2_secrets
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
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    # Environment variables come from SSM Parameter Store
    secrets = local.worker_secrets
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
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    # Environment variables come from SSM Parameter Store
    secrets = local.canvas_secrets
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
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    # Environment variables come from SSM Parameter Store
    secrets = local.urltopng_secrets
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
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    # All environment variables come from SSM Parameter Store
    environment = []
    secrets     = local.gearman_secrets
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
    repositoryCredentials = var.use_ecr ? null : (local.dockerhub_secret_arn != "" ? {
      credentialsParameter = local.dockerhub_secret_arn
    } : null)
    # Environment variables come from SSM Parameter Store
    secrets = local.scheduler_secrets
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
