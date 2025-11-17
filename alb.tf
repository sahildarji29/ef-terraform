# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    enabled = true
    prefix  = "alb"
  }

  tags = {
    Name = "${var.cluster_name}-alb"
  }
}

# S3 Bucket for ALB Access Logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.cluster_name}-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.cluster_name}-alb-logs"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

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

  tags = {
    Name = "${var.cluster_name}-app-tg"
  }
}

# Target Group for API2 Service (internal)
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

  tags = {
    Name = "${var.cluster_name}-api2-tg"
  }
}

# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener for App Domain
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = local.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Listener Rule: API Domain
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.app.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api2.arn
  }

  condition {
    host_header {
      values = [var.api_domain]
    }
  }
}

# Listener Rule: Login Domain
resource "aws_lb_listener_rule" "login" {
  listener_arn = aws_lb_listener.app.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    host_header {
      values = [var.login_domain]
    }
  }
}

# Listener Rule: Base Domain
resource "aws_lb_listener_rule" "base" {
  listener_arn = aws_lb_listener.app.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    host_header {
      values = [var.base_domain, "*.${var.base_domain}"]
    }
  }
}

# ACM Certificate (optional - use existing certificate ARN if available)
resource "aws_acm_certificate" "main" {
  count            = var.acm_certificate_arn == "" ? 1 : 0
  domain_name       = var.domain
  validation_method = "DNS"

  subject_alternative_names = [
    var.api_domain,
    var.login_domain,
    var.base_domain,
    "*.${var.base_domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.cluster_name}-cert"
  }
}

# Use existing certificate or newly created one
locals {
  certificate_arn = var.acm_certificate_arn != "" ? var.acm_certificate_arn : aws_acm_certificate.main[0].arn
}

