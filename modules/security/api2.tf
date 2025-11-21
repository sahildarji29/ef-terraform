# API2 security group
resource "aws_security_group" "api2" {
  name        = "${var.cluster_name}-api2-sg"
  description = "Security group for api2 service"
  vpc_id      = var.vpc_id

  # App can call API2
  ingress {
    description     = "From app service"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Allow api2 instances to talk to each other
  ingress {
    description = "From other api2 instances"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Workers can call API2
  ingress {
    description     = "From worker services"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.worker.id]
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
      Name    = "${var.cluster_name}-api2-sg"
      Service = "api2"
    }
  )
}

