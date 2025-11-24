# Security Group for Scheduler Service
resource "aws_security_group" "scheduler" {
  name        = "${var.cluster_name}-scheduler-sg"
  description = "Security group for scheduler service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Scheduler API from app service"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "Scheduler API from api2 service"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.api2.id]
  }

  ingress {
    description = "From other scheduler instances"
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
      Name    = "${var.cluster_name}-scheduler-sg"
      Service = "scheduler"
    }
  )
}

