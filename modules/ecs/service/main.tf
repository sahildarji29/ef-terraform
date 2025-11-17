# ECS Service
resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

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
    for_each = var.enable_service_discovery && var.service_discovery_namespace_id != "" ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.main[0].arn
    }
  }

  depends_on = var.enable_service_discovery && var.service_discovery_namespace_id != "" ? [
    aws_service_discovery_service.main[0]
  ] : []

  tags = merge(
    var.tags,
    {
      Name = var.service_name
    }
  )
}

