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

