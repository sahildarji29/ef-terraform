# Target Group for App Service
resource "aws_lb_target_group" "app" {
  name                 = "${var.cluster_name}-app-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5  # More tolerant for startup
    timeout             = 10  # Longer timeout
    interval            = 30
    path                = "/"  # Root path for health check
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-app-tg"
    }
  )
}

# Target Group for API2 Service
resource "aws_lb_target_group" "api2" {
  name                 = "${var.cluster_name}-api2-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5  # More tolerant
    timeout             = 10  # Longer timeout
    interval            = 30
    path                = "/"  # API2 responds to root
    protocol            = "HTTP"
    matcher             = "200-499"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-api2-tg"
    }
  )
}

# Target Group for Canvas Service
resource "aws_lb_target_group" "canvas" {
  name                 = "${var.cluster_name}-canvas-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-499"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-canvas-tg"
    }
  )
}

# Target Group for URL to PNG Service
resource "aws_lb_target_group" "urltopng" {
  name                 = "${var.cluster_name}-urltopng-tg"
  port                 = 3000
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-499"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-urltopng-tg"
    }
  )
}

