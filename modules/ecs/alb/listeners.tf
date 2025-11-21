# HTTP listener - redirects to HTTPS if enabled, otherwise forwards to app
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

# API v2 path routing - goes to API2 service (highest priority)
resource "aws_lb_listener_rule" "api_v2" {
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
resource "aws_lb_listener_rule" "login" {
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

# Listener Rule: API Domain - COMMENTED OUT (no domain yet)
# resource "aws_lb_listener_rule" "api_domain" {
#   listener_arn = aws_lb_listener.https.arn
#   priority     = 100
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.api2.arn
#   }
#
#   condition {
#     host_header {
#       values = [var.api_domain]
#     }
#   }
# }

# Listener Rule: Login Domain - COMMENTED OUT (no domain yet)
# resource "aws_lb_listener_rule" "login" {
#   listener_arn = aws_lb_listener.https.arn
#   priority     = 200
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
#
#   condition {
#     host_header {
#       values = [var.login_domain]
#     }
#   }
# }

# Listener Rule: Base Domain - COMMENTED OUT (no domain yet)
# resource "aws_lb_listener_rule" "base" {
#   listener_arn = aws_lb_listener.https.arn
#   priority     = 300
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
#
#   condition {
#     host_header {
#       values = [var.base_domain, "*.${var.base_domain}"]
#     }
#   }
# }

