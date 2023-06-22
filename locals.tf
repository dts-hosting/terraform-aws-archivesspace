locals {
  api_prefix    = var.staff_prefix != "/" ? "${var.staff_prefix}api/" : "/api/"
  certbot_port  = 80
  data_volume   = "${var.name}-data"
  db_url        = "jdbc:mysql://${var.db_host}:3306/${var.db_name}?useUnicode=true&characterEncoding=UTF-8&user=${data.aws_ssm_parameter.db_username.value}&password=${data.aws_ssm_parameter.db_password.value}&useSSL=false&allowPublicKeyRetrieval=true"
  hostnames     = toset([var.public_hostname, var.staff_hostname])
  memory        = var.app_memory + var.solr_memory
  oai_prefix    = var.public_prefix != "/" ? "${var.public_prefix}oai" : "/oai"
  proxy_port    = 4000
  proxy_type    = var.public_hostname == var.staff_hostname ? "single" : "multi"
  public_url    = "https://${var.public_hostname}${var.public_prefix}"
  solr_url      = "http://${var.network_mode == "awsvpc" ? "localhost" : "solr"}:8983/solr/archivesspace"
  solr_volume   = "${var.name}-solr"
  staff_prefix  = var.staff_prefix != "/" ? trimsuffix(var.staff_prefix, "/") : var.staff_prefix
  staff_url     = "https://${var.staff_hostname}${var.staff_prefix}"
  upstream_host = var.network_mode == "awsvpc" ? "localhost" : "app"

  task_config = {
    api_prefix         = local.api_prefix
    app_data           = local.data_volume
    app_img            = var.app_img
    app_memory         = var.app_memory
    certbot_alb_name   = var.certbot_alb_name
    certbot_domains    = join(",", tolist(local.hostnames))
    certbot_email      = var.certbot_email
    certbot_enabled    = var.certbot_enabled ? "true" : "false"
    certbot_port       = local.certbot_port
    custom_env_cfg     = var.custom_env_cfg
    custom_secrets_cfg = var.custom_secrets_cfg
    db_host            = var.db_host
    db_name            = var.db_name
    db_password_arn    = data.aws_ssm_parameter.db_password.arn
    db_url             = aws_ssm_parameter.db-url.arn
    db_user            = data.aws_ssm_parameter.db_username.value
    initialize_plugins = var.initialize_plugins
    log_group          = aws_cloudwatch_log_group.this.name
    name               = var.name
    network_mode       = var.network_mode
    oai_prefix         = local.oai_prefix
    proxy_port         = local.proxy_port
    proxy_type         = local.proxy_type
    public_hostname    = var.public_hostname
    public_prefix      = var.public_prefix
    public_url         = local.public_url
    region             = data.aws_region.current.name
    solr_data          = local.solr_volume
    solr_img           = var.solr_img
    solr_memory        = var.solr_memory
    solr_url           = local.solr_url
    staff_hostname     = var.staff_hostname
    staff_prefix       = local.staff_prefix
    staff_url          = local.staff_url
    timezone           = var.timezone
    upstream_host      = local.upstream_host
  }

  # setup routes for load balancer
  targets = {
    certbot = {
      container = "certbot"
      arn       = var.http_listener_arn
      hosts     = local.hostnames
      health    = "/health"
      paths     = ["*"]
      port      = local.certbot_port
    }
    proxy = {
      container = "proxy"
      arn       = var.https_listener_arn
      hosts     = local.hostnames
      health    = "/health"
      paths     = ["*"]
      port      = local.proxy_port
    }
  }
}
