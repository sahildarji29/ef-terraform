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

# Domain-based Routing Rules for HTTP (only when HTTPS redirect is disabled)
# These match the Docker Swarm nginx interlock configuration

# Listener Rule: API Domain → API2 service (HTTP only, when redirect disabled)
resource "aws_lb_listener_rule" "api_domain_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 50

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

# Listener Rule: Login Domain → App service (HTTP only)
resource "aws_lb_listener_rule" "login_domain_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 60

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

# Listener Rule: Main Domain → App service (HTTP only)
resource "aws_lb_listener_rule" "main_domain_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 70

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    host_header {
      values = [var.domain]
    }
  }
}

# Listener Rule: Base Domain and Wildcard → App service (HTTP only)
resource "aws_lb_listener_rule" "base_domain_http" {
  count = var.enable_https && var.redirect_http_to_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 80

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

# Path-based Routing Rules
# These work on both HTTP and HTTPS listeners
# When HTTPS redirect is enabled, these only apply to HTTPS listener
# Note: Path-based rules have lower priority than domain-based rules

# Listener Rule: API v2 Path (/api/v2/*) → API2 service (highest priority for specific API)
resource "aws_lb_listener_rule" "api_v2" {
  # Apply to HTTPS if enabled, otherwise HTTP (but only if redirect is disabled)
  listener_arn = var.enable_https && var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 100

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
resource "aws_lb_listener_rule" "app_path" {
  listener_arn = var.enable_https && var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 110

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
resource "aws_lb_listener_rule" "oauth2" {
  listener_arn = var.enable_https && var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 120

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
resource "aws_lb_listener_rule" "api" {
  listener_arn = var.enable_https && var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 130

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
resource "aws_lb_listener_rule" "preview" {
  listener_arn = var.enable_https && var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 200

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

# Listener Rule: Canvas Path (/canvas/*) → Canvas service
resource "aws_lb_listener_rule" "canvas" {
  listener_arn = var.enable_https && var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 210

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
resource "aws_lb_listener_rule" "login_path" {
  listener_arn = var.enable_https && var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 300

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

# Domain-based Routing Rules for HTTPS
# These match the Docker Swarm nginx interlock configuration

# Listener Rule: API Domain → API2 service (highest priority for domain routing)
resource "aws_lb_listener_rule" "api_domain_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 50  # Higher priority than path-based rules

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

# Listener Rule: Login Domain → App service
resource "aws_lb_listener_rule" "login_domain_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 60

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

# Listener Rule: Main Domain → App service
resource "aws_lb_listener_rule" "main_domain_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 70

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    host_header {
      values = [var.domain]
    }
  }
}

# Listener Rule: Base Domain and Wildcard → App service
resource "aws_lb_listener_rule" "base_domain_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 80

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

