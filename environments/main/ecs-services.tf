module "service_app" {
  source = "../../modules/ecs/service"

  cluster_id                        = module.ecs_cluster.cluster_id
  cluster_name                      = var.cluster_name
  service_name                      = "${var.cluster_name}-app"
  task_definition_arn               = module.task_app.task_definition_arn
  desired_count                     = var.app_scale
  subnet_ids                        = module.network.public_subnet_ids
  security_group_ids                = [module.security.app_security_group_id]
  assign_public_ip                  = true
  target_group_arn                  = module.alb.target_group_app_arn
  container_name                    = "app"
  container_port                    = 80
  health_check_grace_period_seconds = 120  # Container startPeriod is 90s, add buffer
  enable_execute_command            = true # Enable ECS Exec for debugging
  enable_auto_scaling               = var.enable_auto_scaling
  min_capacity                      = var.min_capacity["app"]
  max_capacity                      = var.max_capacity["app"]
  target_cpu_utilization            = var.target_cpu_utilization
  target_memory_utilization         = var.target_memory_utilization
  scale_in_cooldown                 = var.scale_in_cooldown
  scale_out_cooldown                = var.scale_out_cooldown

  depends_on = [
    module.alb
  ]

  tags = var.tags
}

module "service_api2" {
  source = "../../modules/ecs/service"

  cluster_id                        = module.ecs_cluster.cluster_id
  cluster_name                      = var.cluster_name
  service_name                      = "${var.cluster_name}-api2"
  task_definition_arn               = module.task_api2.task_definition_arn
  desired_count                     = var.api2_scale
  subnet_ids                        = module.network.public_subnet_ids
  security_group_ids                = [module.security.api2_security_group_id]
  assign_public_ip                  = true
  target_group_arn                  = module.alb.target_group_api2_arn
  container_name                    = "api2"
  container_port                    = 80
  health_check_grace_period_seconds = 90   # Container startPeriod is 60s, add buffer
  enable_execute_command            = true # Enable ECS Exec for debugging
  enable_service_discovery          = var.enable_service_discovery
  service_discovery_namespace_id    = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name            = "api2"
  enable_auto_scaling               = var.enable_auto_scaling
  min_capacity                      = var.min_capacity["api2"]
  max_capacity                      = var.max_capacity["api2"]
  target_cpu_utilization            = var.target_cpu_utilization
  target_memory_utilization         = var.target_memory_utilization
  scale_in_cooldown                 = var.scale_in_cooldown
  scale_out_cooldown                = var.scale_out_cooldown

  depends_on = [
    module.alb
  ]

  tags = var.tags
}

module "service_worker" {
  source = "../../modules/ecs/service"

  cluster_id                     = module.ecs_cluster.cluster_id
  cluster_name                   = var.cluster_name
  service_name                   = "${var.cluster_name}-process-job-worker"
  task_definition_arn            = module.task_worker.task_definition_arn
  desired_count                  = var.worker_scale
  subnet_ids                     = module.network.public_subnet_ids
  security_group_ids             = [module.security.worker_security_group_id]
  assign_public_ip               = true
  enable_execute_command         = true # Enable ECS Exec for debugging
  enable_service_discovery       = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name         = "process-job-worker"
  enable_auto_scaling            = var.enable_auto_scaling
  min_capacity                   = var.min_capacity["worker"]
  max_capacity                   = var.max_capacity["worker"]
  target_cpu_utilization         = var.target_cpu_utilization
  target_memory_utilization      = var.target_memory_utilization
  scale_in_cooldown              = var.scale_in_cooldown
  scale_out_cooldown             = var.scale_out_cooldown

  tags = var.tags
}

module "service_canvas" {
  source = "../../modules/ecs/service"

  cluster_id                        = module.ecs_cluster.cluster_id
  cluster_name                      = var.cluster_name
  service_name                      = "${var.cluster_name}-canvas"
  task_definition_arn               = module.task_canvas.task_definition_arn
  desired_count                     = 1
  subnet_ids                        = module.network.public_subnet_ids
  security_group_ids                = [module.security.canvas_security_group_id]
  assign_public_ip                  = true
  target_group_arn                  = module.alb.target_group_canvas_arn
  container_name                    = "canvas"
  container_port                    = 80
  health_check_grace_period_seconds = 90   # Default buffer for canvas startup
  enable_execute_command            = true # Enable ECS Exec for debugging
  enable_service_discovery          = var.enable_service_discovery
  service_discovery_namespace_id    = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name            = "canvas"

  depends_on = [
    module.alb
  ]

  tags = var.tags
}

module "service_urltopng" {
  source = "../../modules/ecs/service"

  cluster_id                        = module.ecs_cluster.cluster_id
  cluster_name                      = var.cluster_name
  service_name                      = "${var.cluster_name}-urltopng"
  task_definition_arn               = module.task_urltopng.task_definition_arn
  desired_count                     = var.urltopng_scale
  subnet_ids                        = module.network.public_subnet_ids
  security_group_ids                = [module.security.urltopng_security_group_id]
  assign_public_ip                  = true
  target_group_arn                  = module.alb.target_group_urltopng_arn
  container_name                    = "urltopng"
  container_port                    = 3000
  health_check_grace_period_seconds = 90   # Container startPeriod is 60s, add buffer
  enable_execute_command            = true # Enable ECS Exec for debugging
  enable_service_discovery          = var.enable_service_discovery
  service_discovery_namespace_id    = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name            = "urltopng"

  depends_on = [
    module.alb
  ]

  tags = var.tags
}

module "service_gearman" {
  source = "../../modules/ecs/service"

  cluster_id                     = module.ecs_cluster.cluster_id
  cluster_name                   = var.cluster_name
  service_name                   = "${var.cluster_name}-gearman-server"
  task_definition_arn            = module.task_gearman.task_definition_arn
  desired_count                  = 1
  subnet_ids                     = module.network.public_subnet_ids
  security_group_ids             = [module.security.gearman_security_group_id]
  assign_public_ip               = true
  enable_execute_command         = true # Enable ECS Exec for debugging
  enable_service_discovery       = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name         = "gearman-server"

  tags = var.tags
}

module "service_scheduler" {
  source = "../../modules/ecs/service"

  cluster_id                     = module.ecs_cluster.cluster_id
  cluster_name                   = var.cluster_name
  service_name                   = "${var.cluster_name}-scheduler"
  task_definition_arn            = module.task_scheduler.task_definition_arn
  desired_count                  = 1
  subnet_ids                     = module.network.public_subnet_ids
  security_group_ids             = [module.security.scheduler_security_group_id]
  assign_public_ip               = true
  enable_execute_command         = true # Enable ECS Exec for debugging
  enable_service_discovery       = var.enable_service_discovery
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
  service_discovery_name         = "scheduler"

  tags = var.tags
}
