resource "aws_lb_target_group" "this" {
  port                 = local.port
  protocol             = "HTTP"
  vpc_id               = local.vpc_id
  target_type          = local.target_type
  deregistration_delay = 0

  health_check {
    path                = "/"
    interval            = 60
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-299,301"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = local.listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    host_header {
      values = [local.arclight_url]
    }
  }
}
