# Security Group for Canvas Service
resource "aws_security_group" "canvas" {
  name        = "${var.cluster_name}-canvas-sg"
  description = "Security group for canvas service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "From app service"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description = "From other canvas instances"
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
      Name    = "${var.cluster_name}-canvas-sg"
      Service = "canvas"
    }
  )
}

