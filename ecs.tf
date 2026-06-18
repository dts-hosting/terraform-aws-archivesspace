resource "aws_ecs_task_definition" "this" {
  family                   = local.name
  network_mode             = local.network_mode
  requires_compatibilities = local.requires_compatibilities
  cpu                      = local.cpu
  memory                   = local.memory
  execution_role_arn       = local.iam_ecs_task_role_arn
  task_role_arn            = local.iam_ecs_task_role_arn

  dynamic "runtime_platform" {
    for_each = local.cpu_architecture == null ? [] : [1]

    content {
      operating_system_family = "LINUX"
      cpu_architecture        = local.cpu_architecture
    }
  }

  container_definitions = templatefile("${path.module}/task-definition/archivesspace.json.tpl", local.task_config)

  volume {
    name = local.indexer_pui_state_volume

    efs_volume_configuration {
      file_system_id     = local.efs_id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.indexer_pui_state.id
      }
    }
  }

  volume {
    name = local.indexer_state_volume

    efs_volume_configuration {
      file_system_id     = local.efs_id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.indexer_state.id
      }
    }
  }
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

  dynamic "load_balancer" {
    for_each = local.targets
    content {
      container_name   = load_balancer.value.container
      container_port   = load_balancer.value.port
      target_group_arn = aws_lb_target_group.this[load_balancer.key].arn
    }
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
    for_each = local.placement_strategies
    content {
      field = ordered_placement_strategy.value.field
      type  = ordered_placement_strategy.value.type
    }
  }

  tags = local.tags
}

resource "aws_efs_access_point" "indexer_pui_state" {
  file_system_id = local.efs_id

  root_directory {
    path = "/${local.indexer_pui_state_volume}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

resource "aws_efs_access_point" "indexer_state" {
  file_system_id = local.efs_id

  root_directory {
    path = "/${local.indexer_state_volume}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

resource "aws_ssm_parameter" "db-url" {
  name  = "${local.name}-db-url"
  type  = "SecureString"
  value = local.db_url
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${local.name}"
  retention_in_days = 7
}

resource "random_password" "secret_key" {
  length  = 16
  special = false
}
