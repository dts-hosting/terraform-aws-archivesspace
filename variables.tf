data "aws_region" "current" {}

data "aws_ssm_parameter" "db_password" {
  name = var.db_password_param
}

data "aws_ssm_parameter" "db_username" {
  name = var.db_username_param
}

variable "app_api_ips_allowed" {
  default     = ["0.0.0.0/0"]
  description = "List of IP addresses (CIDR notation) allowed access to the API"
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

variable "app_pui_ips_allowed" {
  default     = ["0.0.0.0/0"]
  description = "List of IP addresses (CIDR notation) allowed access to the PUI"
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
  description = "Task level CPU allocation"
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

variable "db_migrate" {
  default     = false
  description = "Run the ArchivesSpace database migration script on startup"
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

variable "java_cpu" {
  default     = 1
  description = "Set the allocated cpu for the jvm"
}

variable "java_opts" {
  default = "-Djava.awt.headless=true -Dfile.encoding=UTF-8 -server -Xss512k -Djavax.accessibility.assistive_technologies=''"
}

variable "name" {
  description = "AWS ECS resources name/alias (service name, task definition name etc.)"
}

variable "network_mode" {
  default = "awsvpc"
}

variable "placement_strategies" {
  default = {
    pack-by-memory = {
      field = "memory"
      type  = "binpack"
    }
  }
}

variable "public_enabled" {
  type        = bool
  default     = true
  description = "Control access to the public interface (false overrides public hostname/prefix, prevents all remote access & disables the indexer)"
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

variable "task_memory" {
  default     = 3072
  description = "Memory allocation for task (must be >= app + solr memory)"
}

variable "timezone" {
  description = "Timezone"
}

variable "vpc_id" {
  description = "VPC id"
}
