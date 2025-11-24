# Security Group for Gearman Server Service
resource "aws_security_group" "gearman" {
  name        = "${var.cluster_name}-gearman-sg"
  description = "Security group for gearman-server service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Gearman from workers"
    from_port       = 4730
    to_port         = 4730
    protocol        = "tcp"
    security_groups = [aws_security_group.worker.id]
  }

  ingress {
    description = "From other gearman instances"
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
      Name    = "${var.cluster_name}-gearman-sg"
      Service = "gearman-server"
    }
  )
}

