# HTTP Listener (forwards to app - no HTTPS/domain for now)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTPS Listener - COMMENTED OUT (no certificate/domain yet)
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = var.certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
# }

# Listener Rule: API Domain - COMMENTED OUT (no domain yet)
# resource "aws_lb_listener_rule" "api" {
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

