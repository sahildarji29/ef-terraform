variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "service_names" {
  description = "List of service names to create log groups for"
  type        = list(string)
  default = [
    "app",
    "api2",
    "process-job-worker",
    "canvas",
    "urltopng",
    "gearman-server",
    "scheduler"
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

