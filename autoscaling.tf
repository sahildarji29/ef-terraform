# Auto Scaling Target for App Service
resource "aws_appautoscaling_target" "app" {
  count              = var.enable_auto_scaling ? 1 : 0
  max_capacity       = var.max_capacity["app"]
  min_capacity       = var.min_capacity["app"]
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy for App Service - CPU
resource "aws_appautoscaling_policy" "app_cpu" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "${var.cluster_name}-app-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[0].resource_id
  scalable_dimension = aws_appautoscaling_target.app[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Policy for App Service - Memory
resource "aws_appautoscaling_policy" "app_memory" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "${var.cluster_name}-app-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[0].resource_id
  scalable_dimension = aws_appautoscaling_target.app[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Target for API2 Service
resource "aws_appautoscaling_target" "api2" {
  count              = var.enable_auto_scaling ? 1 : 0
  max_capacity       = var.max_capacity["api2"]
  min_capacity       = var.min_capacity["api2"]
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api2.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy for API2 Service - CPU
resource "aws_appautoscaling_policy" "api2_cpu" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "${var.cluster_name}-api2-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api2[0].resource_id
  scalable_dimension = aws_appautoscaling_target.api2[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.api2[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Target for Process Job Worker
resource "aws_appautoscaling_target" "worker" {
  count              = var.enable_auto_scaling ? 1 : 0
  max_capacity       = var.max_capacity["worker"]
  min_capacity       = var.min_capacity["worker"]
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.process_job_worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy for Worker - CPU
resource "aws_appautoscaling_policy" "worker_cpu" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "${var.cluster_name}-worker-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker[0].resource_id
  scalable_dimension = aws_appautoscaling_target.worker[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

