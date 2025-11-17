# Service Discovery Services
resource "aws_service_discovery_service" "gearman_server" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "gearman-server"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_grace_period_seconds = 30
}

resource "aws_service_discovery_service" "api2" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "api2"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_grace_period_seconds = 30
}

resource "aws_service_discovery_service" "canvas" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "canvas"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_grace_period_seconds = 30
}

resource "aws_service_discovery_service" "urltopng" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "urltopng"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_grace_period_seconds = 30
}

resource "aws_service_discovery_service" "scheduler" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "scheduler"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_grace_period_seconds = 30
}

# ECS Service: App
resource "aws_ecs_service" "app" {
  name            = "${var.cluster_name}-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_scale
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 80
  }

  # App service doesn't need service discovery registration (it's front-facing)

  depends_on = [
    aws_lb_listener.app,
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "${var.cluster_name}-app-service"
  }
}

# ECS Service: API2
resource "aws_ecs_service" "api2" {
  name            = "${var.cluster_name}-api2"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api2.arn
  desired_count   = var.api2_scale
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = var.enable_service_discovery ? aws_service_discovery_service.api2[0].arn : null
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "${var.cluster_name}-api2-service"
  }
}

# ECS Service: Process Job Worker
resource "aws_ecs_service" "process_job_worker" {
  name            = "${var.cluster_name}-process-job-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.process_job_worker.arn
  desired_count   = var.worker_scale
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_internal.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution,
    aws_ecs_service.gearman_server
  ]

  tags = {
    Name = "${var.cluster_name}-process-job-worker-service"
  }
}

# ECS Service: Canvas
resource "aws_ecs_service" "canvas" {
  name            = "${var.cluster_name}-canvas"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.canvas.arn
  desired_count   = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = var.enable_service_discovery ? aws_service_discovery_service.canvas[0].arn : null
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "${var.cluster_name}-canvas-service"
  }
}

# ECS Service: URL to PNG
resource "aws_ecs_service" "urltopng" {
  name            = "${var.cluster_name}-urltopng"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.urltopng.arn
  desired_count   = var.urltopng_scale
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = var.enable_service_discovery ? aws_service_discovery_service.urltopng[0].arn : null
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "${var.cluster_name}-urltopng-service"
  }
}

# ECS Service: Gearman Server
resource "aws_ecs_service" "gearman_server" {
  name            = "${var.cluster_name}-gearman-server"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gearman_server.arn
  desired_count   = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_internal.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = var.enable_service_discovery ? aws_service_discovery_service.gearman_server[0].arn : null
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "${var.cluster_name}-gearman-server-service"
  }
}

# ECS Service: Scheduler
resource "aws_ecs_service" "scheduler" {
  name            = "${var.cluster_name}-scheduler"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.scheduler.arn
  desired_count   = 1
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_internal.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = var.enable_service_discovery ? aws_service_discovery_service.scheduler[0].arn : null
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "${var.cluster_name}-scheduler-service"
  }
}

