output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

# Service-specific security groups
output "app_security_group_id" {
  description = "Security group ID for app service"
  value       = aws_security_group.app.id
}

output "api2_security_group_id" {
  description = "Security group ID for api2 service"
  value       = aws_security_group.api2.id
}

output "worker_security_group_id" {
  description = "Security group ID for worker service"
  value       = aws_security_group.worker.id
}

output "canvas_security_group_id" {
  description = "Security group ID for canvas service"
  value       = aws_security_group.canvas.id
}

output "urltopng_security_group_id" {
  description = "Security group ID for urltopng service"
  value       = aws_security_group.urltopng.id
}

output "gearman_security_group_id" {
  description = "Security group ID for gearman service"
  value       = aws_security_group.gearman.id
}

output "scheduler_security_group_id" {
  description = "Security group ID for scheduler service"
  value       = aws_security_group.scheduler.id
}

# Legacy outputs for backward compatibility (deprecated - use service-specific outputs)
output "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks (deprecated - use app_security_group_id)"
  value       = aws_security_group.app.id
}

output "ecs_internal_security_group_id" {
  description = "Security group ID for internal ECS services (deprecated - use service-specific outputs)"
  value       = aws_security_group.worker.id
}

