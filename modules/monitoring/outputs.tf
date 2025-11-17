output "log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    for k, v in aws_cloudwatch_log_group.services : k => {
      name   = v.name
      arn    = v.arn
    }
  }
}

output "log_group_names" {
  description = "Map of service names to log group names"
  value = {
    for k, v in aws_cloudwatch_log_group.services : k => v.name
  }
}

