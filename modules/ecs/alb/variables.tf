variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "enable_access_logs" {
  description = "Enable access logs"
  type        = bool
  default     = true
}

variable "access_logs_bucket" {
  description = "S3 bucket for access logs"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 prefix for access logs"
  type        = string
  default     = "alb"
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS (leave empty to disable HTTPS)"
  type        = string
  default     = ""
}

variable "enable_https" {
  description = "Enable HTTPS listener (requires certificate_arn)"
  type        = bool
  default     = false
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  validation {
    condition     = contains(["ELBSecurityPolicy-TLS13-1-2-2021-06", "ELBSecurityPolicy-TLS13-1-3-2021-06", "ELBSecurityPolicy-TLS-1-2-2017-01", "ELBSecurityPolicy-TLS-1-1-2017-01"], var.ssl_policy)
    error_message = "SSL policy must be a valid AWS ELB security policy."
  }
}

variable "redirect_http_to_https" {
  description = "Redirect HTTP traffic to HTTPS (only works if enable_https is true)"
  type        = bool
  default     = true
}

variable "domain" {
  description = "Main domain"
  type        = string
}

variable "api_domain" {
  description = "API domain"
  type        = string
}

variable "login_domain" {
  description = "Login domain"
  type        = string
}

variable "base_domain" {
  description = "Base domain"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

