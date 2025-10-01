variable "archivesspace_img" {
  default = "archivesspace/archivesspace:latest"
}

variable "certificate_domain" {
  default = "*.archivesspace.org"
}

variable "domain" {
  default = "archivesspace.org"
}

variable "profile" {
  default = "default"
}

variable "profile_for_dns" {
  default = "default"
}

variable "solr_img" {
  default = "archivesspace/solr:latest"
}

provider "aws" {
  region  = local.region
  profile = var.profile
}

provider "aws" {
  region  = local.region
  profile = var.profile_for_dns
  alias   = "dns"
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_acm_certificate" "issued" {
  domain   = var.certificate_domain
  statuses = ["ISSUED"]
}
data "aws_route53_zone" "selected" {
  provider = aws.dns
  name     = "${var.domain}."
}

data "aws_iam_role" "ecs_task_role" {
  name = local.iam_ecs_task_role_name
}

locals {
  name    = "archivesspace-ex-${basename(path.cwd)}"
  region  = "us-west-2"
  service = "ex-complete"

  iam_ecs_task_role_arn = "aspace-dcsp-production-ECSTaskRole"
  vpc_cidr              = "10.99.0.0/18"
  azs                   = slice(data.aws_availability_zones.available.names, 0, 3)

  db_engine  = "mysql"
  db_version = "8.0"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/dts-hosting/terraform-aws-archivesspace"
  }
}

################################################################################
# ArchivesSpace resources
################################################################################

module "solr" {
  source = "../../modules/solr"

  cluster_id           = data.aws_ecs_cluster.selected.id
  cpu                  = null
  efs_id               = data.aws_efs_file_system.selected.id
  img                  = var.solr_img
  name                 = "${local.service}-solr"
  security_group_id    = data.aws_security_group.selected.id
  service_discovery_id = aws_service_discovery_private_dns_namespace.this.id
  subnets              = data.aws_subnets.selected.ids
  vpc_id               = data.aws_vpc.selected.id

  # networking (tests Solr on ec2 with service discovery)
  capacity_provider        = "EC2"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
}

module "archivesspace" {
  source = "../.."

  cluster_id            = module.ecs.cluster_id
  db_host               = module.db.db_instance_address
  db_name               = "archivesspace"
  db_password_param     = aws_ssm_parameter.db_password.name
  db_username_param     = aws_ssm_parameter.db_username.name
  efs_id                = module.efs.id
  https_listener_arn    = module.alb.https_listener_arns[0]
  iam_ecs_task_role_arn = data.aws_iam_role.ecs_task_role.arn
  img                   = var.archivesspace_img
  name                  = local.service
  public_hostname       = "${local.name}.${var.domain}"
  security_group_id     = module.archivesspace_sg.security_group_id
  solr_url              = "http://${local.service}-solr.aspace.solr:8983/solr/archivesspace"
  staff_hostname        = "${local.name}.${var.domain}"
  staff_prefix          = "/staff/"
  subnets               = module.vpc.private_subnets
  timezone              = "America/New_York"
  vpc_id                = module.vpc.vpc_id

  # custom env & secrets
  custom_env_cfg = {
    "APPCONFIG_EMAIL_DELIVERY_METHOD"     = ":test"
    "APPCONFIG_GLOBAL_EMAIL_FROM_ADDRESS" = "no-reply@example.org"
    "SMTP_ADDRESS"                        = "mail.example.org"
    "SMTP_DOMAIN"                         = "example.org"
  }

  # secrets can use arn or param name (if in the same account)
  custom_secrets_cfg = {
    "SMTP_PASSWORD" = aws_ssm_parameter.db_password.name
    "SMTP_USERNAME" = aws_ssm_parameter.db_username.name
  }

  depends_on = [module.solr]
}

################################################################################
# Supporting resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  create_database_subnet_group  = true
  enable_dns_hostnames          = true
  enable_dns_support            = true
  enable_nat_gateway            = true
  map_public_ip_on_launch       = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false
  single_nat_gateway            = true

  tags = local.tags
}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name}-alb"
  description = "ALB security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

module "archivesspace_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name}-archivesspace"
  description = "Complete ArchivesSpace example security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "EFS access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "EFS access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 4000
      to_port     = 4000
      protocol    = "tcp"
      description = "ArchivesSpace proxy access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "ArchivesSpace staff ui access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 8081
      to_port     = 8081
      protocol    = "tcp"
      description = "ArchivesSpace public ui access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 8082
      to_port     = 8082
      protocol    = "tcp"
      description = "ArchivesSpace oai access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 8089
      to_port     = 8089
      protocol    = "tcp"
      description = "ArchivesSpace api access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 8983
      to_port     = 8983
      protocol    = "tcp"
      description = "Solr access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.0.0"

  name               = local.name
  load_balancer_type = "application"

  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.public_subnets
  security_groups       = [module.alb_sg.security_group_id]
  create_security_group = false

  listeners = {
    http = {
      action_type = "redirect"
      port        = 80
      protocol    = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      action_type     = "fixed-response"
      certificate_arn = data.aws_acm_certificate.issued.arn
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-2016-08"

      fixed_response = {
        content_type = "text/plain"
        message_body = "Nothing to see here!"
        status_code  = "200"
      }
    }
  }

  tags = local.tags
}

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.8.0"

  # File system
  name      = local.name
  encrypted = true

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  # File system policy
  attach_policy                      = true
  bypass_policy_lockout_safety_check = false
  deny_nonsecure_transport           = false

  policy_statements = [
    {
      sid     = "ClientMount"
      actions = ["elasticfilesystem:ClientMount"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
    },
    {
      sid     = "ClientRootAccess"
      actions = ["elasticfilesystem:ClientRootAccess"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
    },
    {
      sid     = "ClientWrite"
      actions = ["elasticfilesystem:ClientWrite"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
    }
  ]

  # Mount targets / security group
  mount_targets              = { for k, v in zipmap(local.azs, module.vpc.private_subnets) : k => { subnet_id = v } }
  security_group_description = "EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      description = "NFS ingress from VPC"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  tags = local.tags
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.6.0"

  cluster_name = local.name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.tags
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.13.0"

  identifier = local.name

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = local.db_engine
  engine_version       = local.db_version
  family               = "${local.db_engine}${local.db_version}" # mysql8
  major_engine_version = local.db_version
  instance_class       = "db.t4g.small"

  allocated_storage     = 20
  max_allocated_storage = 100

  password = aws_ssm_parameter.db_password.value
  username = aws_ssm_parameter.db_username.value

  manage_master_user_password = false
  multi_az                    = false
  db_subnet_group_name        = module.vpc.database_subnet_group
  vpc_security_group_ids      = [module.archivesspace_sg.security_group_id]

  enabled_cloudwatch_logs_exports = []
  create_cloudwatch_log_group     = true

  apply_immediately       = true
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  parameters = [
    {
      name  = "character_set_database"
      value = "utf8"
    },
    {
      name  = "character_set_filesystem"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    },
    {
      name  = "collation_server"
      value = "utf8_unicode_ci"
    },
    {
      name  = "log_bin_trust_function_creators"
      value = "1"
    }
  ]

  tags = local.tags
}

resource "aws_route53_record" "this" {
  provider = aws.dns

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${local.name}.${var.domain}"
  type    = "A"

  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name = "aspace.solr"
  vpc  = module.vpc.vpc_id
}

resource "aws_ssm_parameter" "db_password" {
  name  = "${local.name}-db-password"
  type  = "SecureString"
  value = "testing123"

  tags = local.tags
}

resource "aws_ssm_parameter" "db_username" {
  name  = "${local.name}-db-username"
  type  = "SecureString"
  value = "aspace"

  tags = local.tags
}
