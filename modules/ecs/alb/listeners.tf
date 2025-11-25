# HTTP Listener
# If HTTPS is enabled and redirect is enabled, HTTP redirects to HTTPS
# Otherwise, HTTP forwards traffic normally with domain and path-based routing
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Redirect to HTTPS if enabled
  dynamic "default_action" {
    for_each = var.enable_https && var.redirect_http_to_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  # Default: forward to app (when HTTPS redirect is off)
  dynamic "default_action" {
    for_each = var.enable_https && var.redirect_http_to_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app.arn
    }
  }
}

# Path-based Routing Rules
# These work on both HTTP and HTTPS listeners

# Listener Rule: API v2 Path (/api/v2/*) → API2 service (highest priority for specific API)
# Create on HTTP listener (when redirect is disabled)
resource "aws_lb_listener_rule" "api_v2_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api2.arn
  }

  condition {
    path_pattern {
      values = ["/api/v2/*"]
    }
  }
}

# Create on HTTPS listener (when HTTPS is enabled)

resource "aws_lb_listener_rule" "api_v2_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api2.arn
  }

  condition {
    path_pattern {
      values = ["/api/v2/*"]
    }
  }
}

# Listener Rule: App Path (/app/*) → API2 service
resource "aws_lb_listener_rule" "app_path_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api2.arn
  }

  condition {
    path_pattern {
      values = ["/app/*"]
    }
  }
}

resource "aws_lb_listener_rule" "app_path_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api2.arn
  }

  condition {
    path_pattern {
      values = ["/app/*"]
    }
  }
}

# Listener Rule: OAuth2 Path (/oauth2/*) → API2 service
resource "aws_lb_listener_rule" "oauth2_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api2.arn
  }

  condition {
    path_pattern {
      values = ["/oauth2/*"]
    }
  }
}

resource "aws_lb_listener_rule" "oauth2_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api2.arn
  }

  condition {
    path_pattern {
      values = ["/oauth2/*"]
    }
  }
}

# Listener Rule: API Path (/api/*) → API2 service (catch-all for /api)
resource "aws_lb_listener_rule" "api_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api2.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "api_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api2.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# Listener Rule: Preview Path (/preview/*) → URL to PNG service
resource "aws_lb_listener_rule" "preview_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.urltopng.arn
  }

  condition {
    path_pattern {
      values = ["/preview/*"]
    }
  }
}

resource "aws_lb_listener_rule" "preview_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.urltopng.arn
  }

  condition {
    path_pattern {
      values = ["/preview/*"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Listener Rule: Canvas Path (/canvas/*) → Canvas service
resource "aws_lb_listener_rule" "canvas_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.canvas.arn
  }

  condition {
    path_pattern {
      values = ["/canvas/*"]
    }
  }
}

resource "aws_lb_listener_rule" "canvas_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.canvas.arn
  }

  condition {
    path_pattern {
      values = ["/canvas/*"]
    }
  }
}

# Listener Rule: Login Path (/login/*) → App service
resource "aws_lb_listener_rule" "login_path_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 70

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/login/*"]
    }
  }
}

resource "aws_lb_listener_rule" "login_path_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 70

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/login/*"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTPS Listener
# Only created if enable_https is true and certificate_arn is provided
resource "aws_lb_listener" "https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  # Default action: forward to app service
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


