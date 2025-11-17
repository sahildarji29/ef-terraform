# Security Group for Process Job Worker Service
resource "aws_security_group" "worker" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Security group for process-job-worker service"
  vpc_id      = var.vpc_id

  # Note: Workers make outbound connections to app/api2 (egress is allowed)
  # Workers don't need ingress from app/api2 - they pull jobs from Gearman

  # Allow communication with other workers
  ingress {
    description = "From other worker instances"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Note: Workers connect TO gearman server, so gearman security group allows from workers
  # No need for ingress rule here - workers initiate the connection

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

