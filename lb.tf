resource "aws_lb_target_group" "this" {
  for_each = local.targets

  name                 = "${var.name}-${each.key}"
  port                 = each.value.port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = 0

  health_check {
    path                = each.value.health
    interval            = 60
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-299,301"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = local.targets

  listener_arn = each.value.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    host_header {
      values = each.value.hosts
    }
  }

  condition {
    path_pattern {
      values = each.value.paths
    }
  }
}
