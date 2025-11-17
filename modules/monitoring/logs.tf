# CloudWatch Log Groups for all services
resource "aws_cloudwatch_log_group" "services" {
  for_each          = toset(var.service_names)
  name              = "/ecs/${var.cluster_name}/${each.value}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.cluster_name}-${each.value}-logs"
      Service     = each.value
    }
  )
}

