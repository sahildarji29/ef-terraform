variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable Container Insights"
  type        = bool
  default     = true
}

variable "enable_service_discovery" {
  description = "Enable AWS Service Discovery"
  type        = bool
  default     = true
}

variable "service_discovery_namespace" {
  description = "Service discovery namespace name"
  type        = string
  default     = "eventfarm.local"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name for execute command"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

