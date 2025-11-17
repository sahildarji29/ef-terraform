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
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
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
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-api2-tg"
    }
  )
}

