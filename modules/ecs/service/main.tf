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
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.main[0].arn
    }
  }

  # Note: depends_on is not needed here because the service_registries block
  # already references aws_service_discovery_service.main[0].arn, which creates
  # an implicit dependency that Terraform will handle automatically.

  tags = merge(
    var.tags,
    {
      Name = var.service_name
    }
  )

  # Ensure service is created before auto-scaling tries to reference it
  # This lifecycle block helps ensure the service resource is fully created
  lifecycle {
    create_before_destroy = true
  }
}

