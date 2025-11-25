# ECS service
resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Enable ECS Exec for running commands in containers
  enable_execute_command = var.enable_execute_command

  # Health check grace period: time to wait before starting ALB health checks
  # Should be >= container startPeriod to allow containers to fully start
  health_check_grace_period_seconds = var.target_group_arn != "" ? var.health_check_grace_period_seconds : null

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }


  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.main[0].arn
    }
  }

  # No explicit depends_on needed - service_registries already creates implicit dependency

  tags = merge(
    var.tags,
    {
      Name = var.service_name
    }
  )

  # Make sure service is fully created before autoscaling kicks in
  lifecycle {
    create_before_destroy = true
  }
}

