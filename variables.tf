data "aws_region" "current" {}

data "aws_ssm_parameter" "db_password" {
  name = var.db_password_param
}

data "aws_ssm_parameter" "db_username" {
  name = var.db_username_param
}

variable "api_ips_allowed" {
  default     = ["0.0.0.0/0"]
  description = "List of IP addresses (CIDR notation) allowed access to the API"
}

variable "aspace_java_xmx" {
  default     = 2048
  description = "ArchivesSpace memory allocation"
}

variable "assign_public_ip" {
  default = false
}

variable "capacity_provider" {
  default = "FARGATE"
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

variable "db_migrate_healthcheck" {
  default     = false
  description = "Whether to enable healthchecks for the ArchivesSpace service when database migrations are enabled"
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

variable "efs_id" {
  description = "EFS id for ArchivesSpace data directory"
}

variable "https_listener_arn" {
  description = "ALB (https) listener arn"
}

variable "iam_ecs_task_role_arn" {
  description = "ARN for ECS task role"
}

variable "img" {
  description = "ArchivesSpace img tag"
}

variable "initialize_plugins" {
  default     = ""
  description = "CSV string of plugin (names) to initialize"
}

variable "instances" {
  default = 1
}

variable "java_opts" {
  default = "-XX:+PerfDisableSharedMem -Xss512k -Dfile.encoding=UTF-8 -Djava.awt.headless=true -Djavax.accessibility.assistive_technologies='' -server"
}

variable "memory" {
  default     = 3072
  description = "Memory allocation for task (must be > aspace_java_xmx)"
}

variable "mysql_img" {
  default     = "mysql:8"
  description = "The MYSQL image to use for the database setup"
}

variable "name" {
  description = "AWS ECS resources name/alias (service name, task definition name etc.)"
}

variable "network_mode" {
  default = "awsvpc"
}

variable "oai_enabled" {
  default = null
}

variable "placement_strategies" {
  default = {
    pack-by-memory = {
      field = "memory"
      type  = "binpack"
    }
  }
}

variable "proxy_img" {
  description = "Proxy img tag"
  default     = "lyrasis/aspace-proxy:latest"
}

variable "public_enabled" {
  type        = bool
  default     = true
  description = "Control access to the public interface (false overrides public hostname/prefix, prevents all remote access & disables the indexer)"
}

variable "public_hostname" {
  description = "Hostname for ArchivesSpace public interface"
}

variable "public_ips_allowed" {
  default     = ["0.0.0.0/0"]
  description = "List of IP addresses (CIDR notation) allowed access to the PUI"
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

variable "solr_url" {
  description = "ArchivesSpace solr url (example: http://localhost:8983/solr/archivesspace)"
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

variable "staff_ips_allowed" {
  default     = ["0.0.0.0/0"]
  description = "List of IP addresses (CIDR notation) allowed access to the SUI"
}

variable "swap_size" {
  default     = 2048
  description = "Swap size"
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
