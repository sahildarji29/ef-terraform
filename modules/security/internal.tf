# Security Group for Internal Services (Workers, Gearman, Scheduler)
resource "aws_security_group" "ecs_internal" {
  name        = "${var.cluster_name}-ecs-internal-sg"
  description = "Security group for internal ECS services (workers, gearman, scheduler)"
  vpc_id      = var.vpc_id

  # Allow communication from app/api2 services
  ingress {
    description     = "From ECS tasks"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Allow internal communication
  ingress {
    description = "Internal communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Gearman port
  ingress {
    description     = "Gearman from workers"
    from_port       = 4730
    to_port         = 4730
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_internal.id]
  }

  # Scheduler port
  ingress {
    description     = "Scheduler API"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
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
      Name = "${var.cluster_name}-ecs-internal-sg"
    }
  )
}

