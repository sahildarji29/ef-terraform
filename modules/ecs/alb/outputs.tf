output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_app_arn" {
  description = "ARN of the app target group"
  value       = aws_lb_target_group.app.arn
}

output "target_group_api2_arn" {
  description = "ARN of the api2 target group"
  value       = aws_lb_target_group.api2.arn
}

output "alb_logs_bucket" {
  description = "S3 bucket for ALB logs (if created)"
  value       = var.enable_access_logs && var.access_logs_bucket == "" ? aws_s3_bucket.alb_logs[0].id : var.access_logs_bucket
}

