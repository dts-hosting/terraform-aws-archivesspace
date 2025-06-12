data "aws_region" "current" {}

resource "random_bytes" "secret_key_base" {
  length = 24 # 24 bytes because BASE64 encoding makes this 32 bytes
}

variable "arclight_url" {
  description = "Arclight URL"
}

variable "assign_public_ip" {
  default = false
}

variable "capacity_provider" {
  default = "FARGATE"
}

variable "cpu" {
  description = "Task level cpu allocation"
  default     = 256
}

variable "cluster_id" {
  description = "ECS cluster id"
}

variable "custom_env_cfg" {
  description = "General environment name/value configuration"
  default     = {}
}

variable "custom_secrets_cfg" {
  description = "General secrets name/value configuration"
  default     = {}
}

variable "iam_ecs_task_role_arn" {
  description = "ARN for ECS task role"
}

variable "img" {
  description = "Arclight docker img"
}

variable "instances" {
  default = 1
}

variable "listener_arn" {
  description = "ALB (https) listener arn"
}

variable "memory" {
  description = "Task level memory allocation (hard limit)"
  default     = 512
}

variable "name" {
  description = "AWS ECS resources name/alias (service name, task definition name etc.)"
}

variable "network_mode" {
  default = "awsvpc"
}

variable "placement_strategies" {
  description = "Placement strategies (does not apply when capacity provider is FARGATE)"
  default = {
    pack-by-memory = {
      field = "memory"
      type  = "binpack"
    }
  }
}

variable "port" {
  description = "Arclight port"
  default     = 3000
}

variable "rails_assume_ssl" {
  description = "RAILS to Assume all access will happen through SSL"
  default     = "true"
}

variable "rails_env" {
  description = "RAILS "
  default     = "production"
}

variable "rails_force_ssl" {
  description = "RAILS to forces all access will happen through SSL"
  default     = "true"
}

variable "rails_log_to_stdout" {
  description = "Output Log to STDOUT"
  default     = "true"
}

variable "rails_serve_static_files" {
  description = "Serve Static Fails"
  default     = "true"
}

variable "requires_compatibilities" {
  default = ["FARGATE"]
}

variable "security_group_id" {
  description = "Security group id"
}

variable "site" {
  description = "The site configuration for Arclight"
}

variable "solr_url" {
  description = "Arclight solr url"
}

variable "storage" {
  description = "Task level storage allocation"
  default     = 25
}

variable "subnets" {
  description = "Subnets"
}

variable "tags" {
  description = "Tags for the DSpace backend service"
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
