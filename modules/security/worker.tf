# Security Group for Process Job Worker Service
resource "aws_security_group" "worker" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Security group for process-job-worker service"
  vpc_id      = var.vpc_id

  ingress {
    description = "From other worker instances"
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
      Name    = "${var.cluster_name}-worker-sg"
      Service = "process-job-worker"
    }
  )
}

