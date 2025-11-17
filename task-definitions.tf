# Task Definition for App Service
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.cluster_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.app_cpu
  memory                   = var.app_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.app_image
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "EF_ENV", value = var.environment },
        { name = "CLUSTER", value = var.cluster_name },
        { name = "DOMAIN", value = var.domain },
        { name = "API_DOMAIN", value = var.api_domain },
        { name = "LOGIN_DOMAIN", value = var.login_domain },
        { name = "BASE_DOMAIN", value = var.base_domain },
      ]

      # Secrets should be stored in AWS Secrets Manager or Parameter Store
      # secrets = [
      #   {
      #     name      = "MYSQL_PASSWORD"
      #     valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.cluster_name}/mysql"
      #   }
      # ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
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
    }
  ])

  tags = {
    Name = "${var.cluster_name}-app-task"
  }
}

# Task Definition for API2 Service
resource "aws_ecs_task_definition" "api2" {
  family                   = "${var.cluster_name}-api2"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.api2_cpu
  memory                   = var.api2_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
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
          "awslogs-group"         = aws_cloudwatch_log_group.api2.name
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
    }
  ])

  tags = {
    Name = "${var.cluster_name}-api2-task"
  }
}

# Task Definition for Process Job Worker
resource "aws_ecs_task_definition" "process_job_worker" {
  family                   = "${var.cluster_name}-process-job-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
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
          "awslogs-group"         = aws_cloudwatch_log_group.process_job_worker.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "worker"
        }
      }
    }
  ])

  tags = {
    Name = "${var.cluster_name}-process-job-worker-task"
  }
}

# Task Definition for Canvas Service
resource "aws_ecs_task_definition" "canvas" {
  family                   = "${var.cluster_name}-canvas"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "canvas"
      image     = var.canvas_image
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "EF_ENV", value = var.environment },
        { name = "CLUSTER", value = var.cluster_name },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.canvas.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "canvas"
        }
      }
    }
  ])

  tags = {
    Name = "${var.cluster_name}-canvas-task"
  }
}

# Task Definition for URL to PNG Service
resource "aws_ecs_task_definition" "urltopng" {
  family                   = "${var.cluster_name}-urltopng"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "urltopng"
      image     = var.urltopng_image
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "STORAGE_PROVIDER", value = "s3" },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "PUPPETEER_WAIT_UNTIL", value = "networkidle2" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.urltopng.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "urltopng"
        }
      }
    }
  ])

  tags = {
    Name = "${var.cluster_name}-urltopng-task"
  }
}

# Task Definition for Gearman Server
resource "aws_ecs_task_definition" "gearman_server" {
  family                   = "${var.cluster_name}-gearman-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "gearman-server"
      image     = var.gearman_server_image
      essential = true

      portMappings = [
        {
          containerPort = 4730
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "VERBOSE", value = "INFO" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.gearman_server.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "gearman"
        }
      }
    }
  ])

  tags = {
    Name = "${var.cluster_name}-gearman-server-task"
  }
}

# Task Definition for Scheduler
resource "aws_ecs_task_definition" "scheduler" {
  family                   = "${var.cluster_name}-scheduler"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
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

      portMappings = [
        {
          containerPort = 4000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "EF_ENV", value = var.environment },
        { name = "CLUSTER", value = var.cluster_name },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.scheduler.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "scheduler"
        }
      }
    }
  ])

  tags = {
    Name = "${var.cluster_name}-scheduler-task"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution" {
  name = "${var.cluster_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Tasks
resource "aws_iam_role" "ecs_task" {
  name = "${var.cluster_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Additional IAM policy for tasks (S3, Secrets Manager, etc.)
resource "aws_iam_role_policy" "ecs_task" {
  name = "${var.cluster_name}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*.eventfarm",
          "arn:aws:s3:::*.eventfarm/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "*"
      }
    ]
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

