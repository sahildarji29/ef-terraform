output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "app_service_name" {
  description = "Name of the app ECS service"
  value       = aws_ecs_service.app.name
}

output "api2_service_name" {
  description = "Name of the api2 ECS service"
  value       = aws_ecs_service.api2.name
}

output "worker_service_name" {
  description = "Name of the process-job-worker ECS service"
  value       = aws_ecs_service.process_job_worker.name
}

output "service_discovery_namespace" {
  description = "Service discovery namespace (if enabled)"
  value       = var.enable_service_discovery ? aws_service_discovery_private_dns_namespace.main[0].name : null
}

output "service_discovery_namespace_id" {
  description = "Service discovery namespace ID (if enabled)"
  value       = var.enable_service_discovery ? aws_service_discovery_private_dns_namespace.main[0].id : null
}

output "security_group_alb_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "security_group_ecs_tasks_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "security_group_ecs_internal_id" {
  description = "Security group ID for internal ECS services"
  value       = aws_security_group.ecs_internal.id
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    app                = aws_cloudwatch_log_group.app.name
    api2               = aws_cloudwatch_log_group.api2.name
    process_job_worker = aws_cloudwatch_log_group.process_job_worker.name
    canvas             = aws_cloudwatch_log_group.canvas.name
    urltopng           = aws_cloudwatch_log_group.urltopng.name
    gearman_server      = aws_cloudwatch_log_group.gearman_server.name
    scheduler          = aws_cloudwatch_log_group.scheduler.name
  }
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = local.certificate_arn
}

output "alb_target_group_app_arn" {
  description = "ARN of the app target group"
  value       = aws_lb_target_group.app.arn
}

output "alb_target_group_api2_arn" {
  description = "ARN of the api2 target group"
  value       = aws_lb_target_group.api2.arn
}

