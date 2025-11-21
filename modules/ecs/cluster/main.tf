# ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.cluster_name}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  dynamic "configuration" {
    for_each = var.log_group_name != "" ? [1] : []
    content {
      execute_command_configuration {
        logging = "OVERRIDE"
        log_configuration {
          cloud_watch_log_group_name = var.log_group_name
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster"
    }
  )
}

