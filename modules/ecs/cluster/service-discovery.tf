# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  count = var.enable_service_discovery ? 1 : 0
  name  = var.service_discovery_namespace
  vpc   = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-service-discovery"
    }
  )
}

