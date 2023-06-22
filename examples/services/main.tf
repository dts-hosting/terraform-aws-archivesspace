terraform {
  cloud {
    organization = "Lyrasis"

    workspaces {
      name = "aspace-module-services-test"
    }
  }
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [var.project_account_id]

  assume_role {
    role_arn = "arn:aws:iam::${var.project_account_id}:role/${var.role}"
  }
}

provider "aws" {
  alias               = "dns"
  region              = local.region
  allowed_account_ids = [var.dns_account_id]

  assume_role {
    role_arn = "arn:aws:iam::${var.dns_account_id}:role/${var.role}"
  }
}

locals {
  name   = "archivesspace-${basename(path.cwd)}"
  region = "us-west-2"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/dts-hosting/terraform-aws-archivesspace"
  }
}

################################################################################
# ArchivesSpace resources
################################################################################

module "archivesspace" {
  source = "../.."

  app_efs_id         = data.aws_efs_file_system.selected.id
  app_img            = var.archivesspace_img
  certbot_alb_name   = data.aws_lb.selected.name
  certbot_email      = "notifications@${var.domain}"
  certbot_enabled    = true
  cluster_id         = data.aws_ecs_cluster.selected.id
  db_host            = var.db_host
  db_name            = "archivesspace"
  db_password_param  = var.db_password_param
  db_username_param  = var.db_username_param
  http_listener_arn  = data.aws_lb_listener.http.arn
  https_listener_arn = data.aws_lb_listener.https.arn
  name               = "ex-service"
  public_hostname    = "${local.name}-pui.${var.domain}"
  public_prefix      = "/"
  security_group_id  = data.aws_security_group.selected.id
  solr_efs_id        = data.aws_efs_file_system.selected.id
  solr_img           = var.solr_img
  staff_hostname     = "${local.name}-sui.${var.domain}"
  staff_prefix       = "/"
  subnets            = data.aws_subnets.selected.ids
  timezone           = "America/New_York"
  vpc_id             = data.aws_vpc.selected.id
}

################################################################################
# Supporting resources
################################################################################

resource "aws_route53_record" "pui" {
  provider = aws.dns

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${local.name}-pui.${var.domain}"
  type    = "A"

  alias {
    name                   = data.aws_lb.selected.dns_name
    zone_id                = data.aws_lb.selected.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "sui" {
  provider = aws.dns

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${local.name}-sui.${var.domain}"
  type    = "A"

  alias {
    name                   = data.aws_lb.selected.dns_name
    zone_id                = data.aws_lb.selected.zone_id
    evaluate_target_health = false
  }
}
