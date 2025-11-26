data "aws_caller_identity" "current" {}

module "network" {
  source = "../../modules/network"

  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  cluster_name       = var.cluster_name

  tags = var.tags
}

module "security" {
  source = "../../modules/security"

  vpc_id                     = module.network.vpc_id
  cluster_name               = var.cluster_name
  environment                = var.environment
  allowed_cidr_blocks        = var.allowed_cidr_blocks
  database_security_group_id = var.database_security_group_id
  mongodb_security_group_id  = var.mongodb_security_group_id

  tags = var.tags
}

module "iam" {
  source = "../../modules/iam"

  cluster_name = var.cluster_name
  environment  = var.environment

  tags = var.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  cluster_name       = var.cluster_name
  log_retention_days = var.log_retention_days

  tags = var.tags
}

module "ecs_cluster" {
  source = "../../modules/ecs/cluster"

  cluster_name                = var.cluster_name
  enable_container_insights   = true
  enable_service_discovery    = var.enable_service_discovery
  service_discovery_namespace = var.service_discovery_namespace
  vpc_id                      = module.network.vpc_id
  log_group_name              = module.monitoring.log_groups["app"].name

  tags = var.tags
}

module "alb" {
  source = "../../modules/ecs/alb"

  cluster_name               = var.cluster_name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.public_subnet_ids
  security_group_id          = module.security.alb_security_group_id
  enable_deletion_protection = false
  certificate_arn            = var.acm_certificate_arn
  enable_https               = var.acm_certificate_arn != "" ? true : false
  redirect_http_to_https     = var.acm_certificate_arn != "" ? true : false
  domain                     = var.domain
  api_domain                 = var.api_domain
  login_domain               = var.login_domain
  base_domain                = var.base_domain

  tags = var.tags
}
