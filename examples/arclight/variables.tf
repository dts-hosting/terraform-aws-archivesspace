variable "arclight_img" {
  default = "lyrasis/arclight:latest"
}

variable "domain" {
  default = "lyrtech.org"
}

variable "solr_img" {
  default = "lyrasis/arclight-solr:latest"
}

################################################################################
# External resources
################################################################################
variable "department" {}
variable "dns_account_id" {}
variable "environment" {}
variable "project_account_id" {}
variable "region" {}
variable "role" {}
variable "service" {}
### module
variable "cluster_name" {}
variable "efs_name" {}
variable "iam_role" {}
variable "lb_name" {}
variable "security_group_name" {}
variable "site" {}
variable "solr_discovery_namespace" {}
variable "subnet_type" {}
variable "vpc_name" {}

data "aws_ecs_cluster" "selected" {
  cluster_name = var.cluster_name
}

data "aws_efs_file_system" "selected" {
  tags = {
    Name = var.efs_name
  }
}

data "aws_iam_role" "ecs_task_role" {
  name = var.iam_role
}

data "aws_lb" "selected" {
  name = var.lb_name
}

data "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.selected.arn
  port              = 80
}

data "aws_lb_listener" "https" {
  load_balancer_arn = data.aws_lb.selected.arn
  port              = 443
}

data "aws_route53_zone" "selected" {
  provider = aws.dns
  name     = "${var.domain}."
}

data "aws_security_group" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.security_group_name]
  }
}

data "aws_service_discovery_dns_namespace" "solr" {
  name = var.solr_discovery_namespace
  type = "DNS_PRIVATE"
}

data "aws_subnets" "selected" {
  filter {
    name   = "tag:Type"
    values = [var.subnet_type]
  }
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}
