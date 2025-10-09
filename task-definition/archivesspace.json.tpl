[
  {
    "name"  : "createdb",
    "image" : "${mysql_img}",
    "networkMode": "${network_mode}",
    "essential": false,
    "command" : [
      "/bin/sh",
      "-c",
      "mysql --user ${db_user} -e \"CREATE DATABASE IF NOT EXISTS ${db_name} default character set utf8mb4;\""
    ],
    "environment": [
      {
        "name" : "MYSQL_HOST",
        "value" : "${db_host}"
      }
    ],
    "secrets": [
      {
        "name" : "MYSQL_PWD",
        "valueFrom" : "${db_password_arn}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "archivesspace"
      }
    }
  },
  {
    "name": "proxy",
    "image": "${proxy_img}",
    "networkMode": "${network_mode}",
    "essential": true,
    "environment": [
      {
        "name": "API_IPS_ALLOWED",
        "value": "${api_ips_allowed}"
      },
      {
        "name": "API_PREFIX",
        "value": "${api_prefix}"
      },
      {
        "name": "OAI_PREFIX",
        "value": "${oai_prefix}"
      },
      {
        "name": "PROXY_TYPE",
        "value": "${proxy_type}"
      },
      {
        "name": "PUBLIC_NAME",
        "value": "${public_hostname}"
      },
      {
        "name": "PUBLIC_PREFIX",
        "value": "${public_prefix}"
      },
      {
        "name": "PUI_IPS_ALLOWED",
        "value": "${pui_ips_allowed}"
      },
      {
        "name": "STAFF_IPS_ALLOWED",
        "value": "${staff_ips_allowed}"
      },
      {
        "name": "REAL_IP_CIDR",
        "value": "${real_ip_cidr}"
      },
      {
        "name": "STAFF_NAME",
        "value": "${staff_hostname}"
      },
      {
        "name": "STAFF_PREFIX",
        "value": "${staff_prefix}"
      },
      {
        "name": "SUI_IPS_ALLOWED",
        "value": "${sui_ips_allowed}"
      },
      {
        "name": "UPSTREAM_HOST",
        "value": "${upstream_host}"
      }
    ],
    "portMappings": [
      {
        "containerPort": ${proxy_port}
      }
    ],
    "dependsOn": [
      {
        "containerName": "app",
        "condition": "START"
      }
    ],
    %{ if network_mode == "bridge" }
    "links": [
      "app"
    ],
    %{ endif ~}
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "archivesspace"
      }
    }
  },
  {
    "name": "app",
    "image": "${app_img}",
    "networkMode": "${network_mode}",
    "essential": true,
    "environment": [
      %{ for name, value in custom_env_cfg }
      {
        "name": "${name}",
        "value": "${value}"
      },
      %{ endfor ~}
      {
        "name": "APPCONFIG_FRONTEND_COOKIE_SECRET",
        "value": "${secret_key}"
      },
      {
        "name": "APPCONFIG_FRONTEND_PROXY_URL",
        "value": "${staff_url}"
      },
      {
        "name": "APPCONFIG_ENABLE_PUBLIC",
        "value": "${public_enabled}"
      },
      {
        "name": "APPCONFIG_PUBLIC_PROXY_URL",
        "value": "${public_url}"
      },
      {
        "name": "APPCONFIG_ENABLE_OAI",
        "value": "${oai_enabled}"
      },
      {
        "name": "APPCONFIG_OAI_PROXY_URL",
        "value": "${public_url}"
      },
      {
        "name": "APPCONFIG_PUBLIC_COOKIE_SECRET",
        "value": "${secret_key}"
      },
      {
        "name": "APPCONFIG_PUBLIC_USER_SECRET",
        "value": "${secret_key}"
      },
      {
        "name": "APPCONFIG_PUI_INDEXER_ENABLED",
        "value": "${pui_indexer_enabled}"
      },
      {
        "name": "APPCONFIG_REQUEST_USER_SECRET",
        "value": "${secret_key}"
      },
      {
        "name": "APPCONFIG_SEARCH_USER_SECRET",
        "value": "${secret_key}"
      },
      {
        "name": "APPCONFIG_SOLR_URL",
        "value": "${solr_url}"
      },
      {
        "name": "APPCONFIG_STAFF_USER_SECRET",
        "value": "${secret_key}"
      },
      {
        "name": "ASPACE_DB_MIGRATE",
        "value": "${db_migrate}"
      },
      {
        "name": "ASPACE_INITIALIZE_PLUGINS",
        "value": "${initialize_plugins}"
      },
      {
        "name": "ASPACE_JAVA_XMX",
        "value": "-Xmx${app_memory}m"
      },
      {
        "name": "JAVA_OPTS",
        "value": "${java_opts}"
      },
      {
        "name": "TZ",
        "value": "${timezone}"
      }
    ],
    "secrets": [
      %{ for name, value in custom_secrets_cfg }
      {
        "name": "${name}",
        "valueFrom": "${value}"
      },
      %{ endfor ~}
      {
        "name": "APPCONFIG_DB_URL",
        "valueFrom": "${db_url}"
      }
    ],
    "mountPoints": [
      {
        "sourceVolume": "${indexer_pui_state}",
        "containerPath": "/archivesspace/data/indexer_pui_state"
      },
      {
        "sourceVolume": "${indexer_state}",
        "containerPath": "/archivesspace/data/indexer_state"
      }
    ],
    %{ if capacity_provider == "EC2" }
    "linuxParameters": {
        "maxSwap": ${swap_size},
        "swappiness": 60
    },
    %{ endif ~}
    "dependsOn": [
      {
        "containerName": "createdb",
        "condition": "COMPLETE"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "archivesspace"
      }
    }
  }
]
