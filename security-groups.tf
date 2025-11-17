# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

# Security Group for ECS Tasks (App, API2, Canvas, etc.)
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-ecs-tasks-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow internal communication between services
  ingress {
    description = "Internal communication"
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

  tags = {
    Name = "${var.cluster_name}-ecs-tasks-sg"
  }
}

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

  tags = {
    Name = "${var.cluster_name}-ecs-internal-sg"
  }
}

# Security Group Rule: Allow ECS tasks to access RDS
resource "aws_security_group_rule" "ecs_to_rds" {
  count                    = var.database_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id
  security_group_id        = var.database_security_group_id
  description              = "Allow MySQL access from ECS tasks"
}

# Security Group Rule: Allow ECS tasks to access MongoDB
resource "aws_security_group_rule" "ecs_to_mongodb" {
  count                    = var.mongodb_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id
  security_group_id        = var.mongodb_security_group_id
  description              = "Allow MongoDB access from ECS tasks"
}

# Security Group Rule: Allow internal services to access RDS
resource "aws_security_group_rule" "internal_to_rds" {
  count                    = var.database_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_internal.id
  security_group_id        = var.database_security_group_id
  description              = "Allow MySQL access from internal ECS services"
}

# Security Group Rule: Allow internal services to access MongoDB
resource "aws_security_group_rule" "internal_to_mongodb" {
  count                    = var.mongodb_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_internal.id
  security_group_id        = var.mongodb_security_group_id
  description              = "Allow MongoDB access from internal ECS services"
}

