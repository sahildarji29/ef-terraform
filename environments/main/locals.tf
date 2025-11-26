locals {
  dockerhub_secret_arn = var.dockerhub_secret_arn != "" ? var.dockerhub_secret_arn : (var.dockerhub_username != "" ? aws_secretsmanager_secret.dockerhub[0].arn : "")

  account_id   = data.aws_caller_identity.current.account_id
  ecr_registry = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

  app_image_uri       = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-app:${var.app_image_tag}" : var.app_image
  api2_image_uri      = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-api2:${var.api2_image_tag}" : var.api2_image
  canvas_image_uri    = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-canvas:${var.canvas_image_tag}" : var.canvas_image
  worker_image_uri    = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-process-job-worker:${var.process_job_worker_image_tag}" : var.process_job_worker_image
  urltopng_image_uri  = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-urltopng:${var.urltopng_image_tag}" : var.urltopng_image
  gearman_image_uri   = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-gearmand:${var.gearman_server_image_tag}" : var.gearman_server_image
  scheduler_image_uri = var.use_ecr ? "${local.ecr_registry}/${var.cluster_name}-scheduler:${var.scheduler_image_tag}" : var.scheduler_image
}
