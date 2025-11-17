output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "service_names" {
  description = "Names of all ECS services"
  value = {
    app    = module.service_app.service_name
    api2   = module.service_api2.service_name
    worker = module.service_worker.service_name
    canvas = module.service_canvas.service_name
    urltopng = module.service_urltopng.service_name
    gearman = module.service_gearman.service_name
    scheduler = module.service_scheduler.service_name
  }
}

output "service_discovery_namespace" {
  description = "Service discovery namespace (if enabled)"
  value       = module.ecs_cluster.service_discovery_namespace_name
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    alb     = module.security.alb_security_group_id
    ecs     = module.security.ecs_tasks_security_group_id
    internal = module.security.ecs_internal_security_group_id
  }
}

output "log_groups" {
  description = "CloudWatch log group names"
  value       = module.monitoring.log_group_names
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = local.certificate_arn
}

