locals {
  api_ips_allowed          = join("; ", formatlist("allow %s", var.api_ips_allowed))
  api_prefix               = local.staff_prefix != "/" ? "${local.staff_prefix}/api/" : "/api/"
  aspace_java_xmx          = var.aspace_java_xmx
  assign_public_ip         = var.assign_public_ip
  capacity_provider        = var.capacity_provider
  cluster_id               = var.cluster_id
  cpu                      = var.cpu
  custom_env_cfg           = var.custom_env_cfg
  custom_secrets_cfg       = var.custom_secrets_cfg
  db_host                  = var.db_host
  db_migrate               = local.instances != 1 ? false : var.db_migrate # it's not safe to run migrations with > 1 instances running
  db_migrate_healthcheck   = var.db_migrate_healthcheck
  db_name                  = var.db_name
  db_password              = data.aws_ssm_parameter.db_password.value
  db_password_param        = var.db_password_param
  db_username              = data.aws_ssm_parameter.db_username.value
  db_username_param        = var.db_username_param
  db_url                   = "jdbc:mysql://${local.db_host}:3306/${local.db_name}?useUnicode=true&characterEncoding=UTF-8&user=${local.db_username}&password=${local.db_password}&useSSL=false&allowPublicKeyRetrieval=true"
  efs_id                   = var.efs_id
  hostnames                = toset([local.public_hostname, local.staff_hostname])
  https_listener_arn       = var.https_listener_arn
  iam_ecs_task_role_arn    = var.iam_ecs_task_role_arn
  img                      = var.img
  indexer_pui_state_volume = "${local.name}-indexer_pui_state"
  indexer_state_volume     = "${local.name}-indexer_state"
  initialize_plugins       = var.initialize_plugins
  instances                = var.instances
  java_opts                = var.java_opts
  memory                   = var.memory
  mysql_img                = var.mysql_img
  name                     = var.name
  network_mode             = var.network_mode
  oai_enabled              = coalesce(var.oai_enabled, local.public_enabled)
  oai_prefix               = local.public_prefix != "/" ? "${local.public_prefix}oai" : "/oai"
  placement_strategies     = var.placement_strategies
  proxy_img                = var.proxy_img
  proxy_port               = 4000
  proxy_type               = local.public_hostname == local.staff_hostname ? "single" : "multi"
  public_enabled           = var.public_enabled
  proxy_health_path        = local.db_migrate && !local.db_migrate_healthcheck ? "/health" : "/status" # "/health" is a canned response, always returning http status 200
  public_hostname          = local.public_enabled ? var.public_hostname : local.staff_hostname
  public_ips_allowed       = join("; ", formatlist("allow %s", var.public_ips_allowed))
  public_prefix            = local.public_enabled ? var.public_prefix : "/public/"
  public_url               = trimsuffix("https://${local.public_hostname}${local.public_prefix}", "/")
  real_ip_cidr             = "10.0.0.0/16" # TODO: var
  requires_compatibilities = var.requires_compatibilities
  security_group_id        = var.security_group_id
  solr_url                 = var.solr_url
  staff_hostname           = var.staff_hostname
  staff_ips_allowed        = join("; ", formatlist("allow %s", var.staff_ips_allowed))
  staff_prefix             = var.staff_prefix != "/" ? trimsuffix(var.staff_prefix, "/") : var.staff_prefix
  staff_url                = trimsuffix("https://${local.staff_hostname}${local.staff_prefix}", "/")
  subnets                  = var.subnets
  swap_size                = var.swap_size
  tags                     = var.tags
  target_type              = var.target_type
  timezone                 = var.timezone
  upstream_host            = local.network_mode == "awsvpc" ? "localhost" : "app"
  vpc_id                   = var.vpc_id

  task_config = {
    api_ips_allowed     = local.api_ips_allowed
    api_prefix          = local.api_prefix
    app_img             = local.img
    app_memory          = local.aspace_java_xmx
    capacity_provider   = local.capacity_provider
    custom_env_cfg      = local.custom_env_cfg
    custom_secrets_cfg  = local.custom_secrets_cfg
    db_host             = local.db_host
    db_migrate          = local.db_migrate
    db_name             = local.db_name
    db_password_arn     = data.aws_ssm_parameter.db_password.arn
    db_url              = aws_ssm_parameter.db-url.arn
    db_user             = data.aws_ssm_parameter.db_username.value
    indexer_pui_state   = local.indexer_pui_state_volume
    indexer_state       = local.indexer_state_volume
    initialize_plugins  = local.initialize_plugins
    java_opts           = local.java_opts
    log_group           = aws_cloudwatch_log_group.this.name
    mysql_img           = local.mysql_img
    name                = local.name
    network_mode        = local.network_mode
    oai_enabled         = local.oai_enabled
    oai_prefix          = local.oai_prefix
    proxy_img           = local.proxy_img
    proxy_port          = local.proxy_port
    proxy_type          = local.proxy_type
    public_enabled      = local.public_enabled
    public_hostname     = local.public_hostname
    public_prefix       = local.public_prefix
    public_url          = local.public_url
    pui_indexer_enabled = local.public_enabled
    pui_ips_allowed     = local.public_ips_allowed
    real_ip_cidr        = local.real_ip_cidr
    region              = data.aws_region.current.name
    secret_key          = random_password.secret_key.result
    solr_url            = local.solr_url
    staff_hostname      = local.staff_hostname
    staff_prefix        = local.staff_prefix
    staff_url           = local.staff_url
    sui_ips_allowed     = local.staff_ips_allowed
    swap_size           = local.swap_size
    timezone            = local.timezone
    upstream_host       = local.upstream_host
  }

  # setup routes for load balancer
  targets = {
    proxy = {
      container = "proxy"
      arn       = local.https_listener_arn
      hosts     = local.hostnames
      health    = local.proxy_health_path
      paths     = ["*"]
      port      = local.proxy_port
      prefix    = "proxy"
    }
  }
}
