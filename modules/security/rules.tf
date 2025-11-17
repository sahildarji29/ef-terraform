# Security Group Rules: Allow services to access RDS
resource "aws_security_group_rule" "app_to_rds" {
  count                    = var.database_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = var.database_security_group_id
  description              = "Allow MySQL access from app service"
}

resource "aws_security_group_rule" "api2_to_rds" {
  count                    = var.database_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api2.id
  security_group_id        = var.database_security_group_id
  description              = "Allow MySQL access from api2 service"
}

resource "aws_security_group_rule" "worker_to_rds" {
  count                    = var.database_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = var.database_security_group_id
  description              = "Allow MySQL access from worker service"
}

resource "aws_security_group_rule" "scheduler_to_rds" {
  count                    = var.database_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.scheduler.id
  security_group_id        = var.database_security_group_id
  description              = "Allow MySQL access from scheduler service"
}

# Security Group Rules: Allow services to access MongoDB
resource "aws_security_group_rule" "app_to_mongodb" {
  count                    = var.mongodb_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = var.mongodb_security_group_id
  description              = "Allow MongoDB access from app service"
}

resource "aws_security_group_rule" "api2_to_mongodb" {
  count                    = var.mongodb_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api2.id
  security_group_id        = var.mongodb_security_group_id
  description              = "Allow MongoDB access from api2 service"
}

resource "aws_security_group_rule" "worker_to_mongodb" {
  count                    = var.mongodb_security_group_id != "" ? 1 : 0
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = var.mongodb_security_group_id
  description              = "Allow MongoDB access from worker service"
}

