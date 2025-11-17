output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.main.id
}

output "service_discovery_service_id" {
  description = "Service discovery service ID (if enabled)"
  value       = var.enable_service_discovery ? aws_service_discovery_service.main[0].id : null
}

