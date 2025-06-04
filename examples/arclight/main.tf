terraform {
  cloud {
    organization = "Lyrasis"

    workspaces {
      name = "arclight"
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
  name    = "arclight"
  region  = "us-west-2"
  service = "arclight"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/dts-hosting/terraform-aws-archivesspace"
  }
}

module "solr" {
  source = "github.com/dts-hosting/terraform-aws-dspace//modules/solr"

  cluster_id            = data.aws_ecs_cluster.selected.id
  efs_id                = data.aws_efs_file_system.selected.id
  iam_ecs_task_role_arn = data.aws_iam_role.ecs_task_role.arn
  img                   = var.solr_img
  name                  = "${local.name}-solr"
  security_group_id     = data.aws_security_group.selected.id
  service_discovery_id  = data.aws_service_discovery_dns_namespace.solr.id
  subnets               = data.aws_subnets.selected.ids
  vpc_id                = data.aws_vpc.selected.id
  cmd_args = [
    "cp -r /opt/solr/server/solr/configsets/arclight/conf/* /var/solr/data/arclight/conf/;",
    "/opt/docker-solr/scripts/solr-create -p 8983 -c arclight -d arclight || true;",
    "/opt/solr/docker/scripts/solr-create -p 8983 -c arclight -d arclight || true"
  ]
}

module "arclight" {
  source = "../../modules/arclight"

  arclight_url          = "${local.name}.${var.domain}"
  cluster_id            = data.aws_ecs_cluster.selected.id
  iam_ecs_task_role_arn = data.aws_iam_role.ecs_task_role.arn
  img                   = var.arclight_img
  listener_arn          = data.aws_lb_listener.https.arn
  name                  = "${local.name}-web"
  security_group_id     = data.aws_security_group.selected.id
  site                  = var.site
  solr_url              = "http://${local.name}-solr.arclight.solr:8983/solr/arclight"
  subnets               = data.aws_subnets.selected.ids
  timezone              = "America/New_York"
  vpc_id                = data.aws_vpc.selected.id
}

resource "aws_route53_record" "this" {
  provider = aws.dns

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${local.name}.${var.domain}"
  type    = "A"

  alias {
    name                   = data.aws_lb.selected.dns_name
    zone_id                = data.aws_lb.selected.zone_id
    evaluate_target_health = false
  }
}
