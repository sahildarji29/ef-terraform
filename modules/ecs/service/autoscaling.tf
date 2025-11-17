# Auto Scaling - COMMENTED OUT (enable after services are running)
# Uncomment and run terraform apply after services are stable

# # Auto Scaling Target
# # Simple auto-scaling: min 1, max 5, 75% CPU and Memory threshold
# resource "aws_appautoscaling_target" "main" {
#   count              = var.enable_auto_scaling ? 1 : 0
#   max_capacity       = var.max_capacity
#   min_capacity       = var.min_capacity
#   resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"
#
#   # Wait for service to be created
#   # Note: If this fails on first apply, run terraform apply again after services are running
#   depends_on = [aws_ecs_service.main]
# }
#
# # Auto Scaling Policy - CPU (75% threshold)
# resource "aws_appautoscaling_policy" "cpu" {
#   count              = var.enable_auto_scaling ? 1 : 0
#   name               = "${var.service_name}-cpu-autoscaling"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.main[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.main[0].scalable_dimension
#   service_namespace  = aws_appautoscaling_target.main[0].service_namespace
#
#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#     target_value      = 75.0  # 75% CPU threshold
#     scale_in_cooldown = 300   # 5 minutes
#     scale_out_cooldown = 60   # 1 minute
#   }
# }
#
# # Auto Scaling Policy - Memory (75% threshold)
# resource "aws_appautoscaling_policy" "memory" {
#   count              = var.enable_auto_scaling ? 1 : 0
#   name               = "${var.service_name}-memory-autoscaling"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.main[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.main[0].scalable_dimension
#   service_namespace  = aws_appautoscaling_target.main[0].service_namespace
#
#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }
#     target_value      = 75.0  # 75% Memory threshold
#     scale_in_cooldown = 300   # 5 minutes
#     scale_out_cooldown = 60   # 1 minute
#   }
# }
