# Security Group for URL to PNG Service
resource "aws_security_group" "urltopng" {
  name        = "${var.cluster_name}-urltopng-sg"
  description = "Security group for urltopng service"
  vpc_id      = var.vpc_id

  # Allow communication from app service
  ingress {
    description     = "From app service"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Allow communication with other urltopng instances
  ingress {
    description = "From other urltopng instances"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-urltopng-sg"
      Service = "urltopng"
    }
  )
}

