resource "aws_ecs_task_definition" "this" {
  family                   = local.name
  network_mode             = local.network_mode
  requires_compatibilities = local.requires_compatibilities
  cpu                      = local.cpu
  memory                   = local.memory
  execution_role_arn       = local.iam_ecs_task_role_arn
  task_role_arn            = local.iam_ecs_task_role_arn

  ephemeral_storage {
    size_in_gib = local.storage
  }

  container_definitions = templatefile("${path.module}/task-definition/arclight.json.tpl", local.task_config)
}

resource "aws_ecs_service" "this" {
  name            = local.name
  cluster         = local.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = local.instances

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = local.capacity_provider
    weight            = 100
  }

  load_balancer {
    container_name   = "arclight"
    container_port   = local.port
    target_group_arn = aws_lb_target_group.this.arn
  }

  dynamic "network_configuration" {
    for_each = local.network_mode == "awsvpc" ? ["true"] : []
    content {
      assign_public_ip = local.assign_public_ip
      security_groups  = [local.security_group_id]
      subnets          = local.subnets
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = !strcontains(local.capacity_provider, "FARGATE") ? local.placement_strategies : {}
    content {
      field = ordered_placement_strategy.value.field
      type  = ordered_placement_strategy.value.type
    }
  }

  tags = local.tags
}

resource "aws_ssm_parameter" "secret_key_base" {
  name  = "${local.name}-secret-key-base"
  type  = "SecureString"
  value = local.secret_key_base
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${local.name}"
  retention_in_days = 7
}
