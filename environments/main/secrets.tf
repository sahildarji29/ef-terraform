resource "aws_secretsmanager_secret" "dockerhub" {
  count = var.dockerhub_secret_arn == "" && var.dockerhub_username != "" ? 1 : 0

  name        = "${var.cluster_name}-dockerhub-credentials"
  description = "Docker Hub credentials for pulling private images"

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-dockerhub-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "dockerhub" {
  count = var.dockerhub_secret_arn == "" && var.dockerhub_username != "" ? 1 : 0

  secret_id = aws_secretsmanager_secret.dockerhub[0].id
  secret_string = jsonencode({
    username = var.dockerhub_username
    password = var.dockerhub_password
  })
}
