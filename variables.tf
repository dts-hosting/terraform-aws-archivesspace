data "aws_region" "current" {}

data "aws_ssm_parameter" "db_password" {
  name = var.db_password_param
}

data "aws_ssm_parameter" "db_username" {
  name = var.db_username_param
}

variable "app_efs_id" {
  description = "EFS id for ArchivesSpace data directory"
}

variable "app_img" {
  description = "ArchivesSpace img tag"
}

variable "app_memory" {
  default     = 2048
  description = "ArchivesSpace memory allocation"
}

variable "assign_public_ip" {
  default = false
}

variable "capacity_provider" {
  default = "FARGATE"
}

variable "certbot_alb_name" {
  default = ""
}

variable "certbot_email" {
  default = ""
}

variable "certbot_enabled" {
  default = false
}

variable "cluster_id" {
  description = "ECS cluster id"
}

variable "cpu" {
  default     = 1024
  description = "Task level CPU allocation (applies only when using Fargate)"
}

variable "custom_env_cfg" {
  default     = {}
  description = "General environment name/value configuration"
}

variable "custom_secrets_cfg" {
  default     = {}
  description = "General secrets name/value configuration"
}

variable "db_host" {
  description = "ArchivesSpace db host"
}

variable "db_name" {
  description = "ArchivesSpace db name"
}

variable "db_password_param" {
  description = "ArchivesSpace db password SSM parameter name"
}

variable "db_username_param" {
  description = "ArchivesSpace db username SSM parameter name"
}

variable "http_listener_arn" {
  description = "ALB (http) listener arn"
}

variable "https_listener_arn" {
  description = "ALB (https) listener arn"
}

variable "initialize_plugins" {
  default     = ""
  description = "CSV string of plugin (names) to initialize"
}

variable "instances" {
  default = 1
}

variable "name" {
  description = "AWS ECS resources name/alias (service name, task definition name etc.)"
}

variable "network_mode" {
  default = "awsvpc"
}

variable "public_hostname" {
  description = "Hostname for ArchivesSpace public interface"
}

variable "public_prefix" {
  default     = "/"
  description = "Path prefix for ArchivesSpace public interface"

  validation {
    condition     = startswith(var.public_prefix, "/") && endswith(var.public_prefix, "/")
    error_message = "Prefix must end with a slash (/)"
  }
}

variable "requires_compatibilities" {
  default = ["FARGATE"]
}

variable "security_group_id" {
  description = "Security group id"
}

variable "solr_efs_id" {
  description = "EFS id for Solr data"
}

variable "solr_img" {
  description = "Solr img tag"
}

variable "solr_memory" {
  default     = 1024
  description = "Memory allocation for Solr"
}

variable "staff_hostname" {
  description = "Hostname for ArchivesSpace staff interface"
}

variable "staff_prefix" {
  default     = "/"
  description = "Path prefix for ArchivesSpace staff interface"

  validation {
    condition     = startswith(var.staff_prefix, "/") && endswith(var.staff_prefix, "/")
    error_message = "Prefix must end with a slash (/)"
  }
}

variable "subnets" {
  description = "Subnets"
}

variable "tags" {
  description = "Tags for the ArchivesSpace ECS service"
  default     = {}
  type        = map(string)
}

variable "target_type" {
  default = "ip"
}

variable "timezone" {
  description = "Timezone"
}

variable "vpc_id" {
  description = "VPC id"
}
