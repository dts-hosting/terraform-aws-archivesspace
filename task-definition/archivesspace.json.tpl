[
  {
    "name": "certbot",
    "image": "lyrasis/certbot-acm:latest",
    "networkMode": "${network_mode}",
    "essential": true,
    "environment": [
      {
        "name": "CERTBOT_ALB_NAME",
        "value": "${certbot_alb_name}"
      },
      {
        "name": "CERTBOT_DOMAINS",
        "value": "${certbot_domains}"
      },
      {
        "name": "CERTBOT_EMAIL",
        "value": "${certbot_email}"
      },
      {
        "name": "CERTBOT_ENABLED",
        "value": "${certbot_enabled}"
      }
    ],
    "portMappings": [
      {
        "containerPort": ${certbot_port}
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
    "name"  : "createdb",
    "image" : "mysql:8",
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
    "image": "lyrasis/aspace-proxy:latest",
    "networkMode": "${network_mode}",
    "essential": true,
    "environment": [
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
        "name": "STAFF_NAME",
        "value": "${staff_hostname}"
      },
      {
        "name": "STAFF_PREFIX",
        "value": "${staff_prefix}"
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
    %{ if network_mode != "awsvpc" }
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
      {
        "name": "APPCONFIG_FRONTEND_PROXY_URL",
        "value": "${staff_url}"
      },
      {
        "name": "APPCONFIG_PUBLIC_PROXY_URL",
        "value": "${public_url}"
      },
      {
        "name": "APPCONFIG_OAI_PROXY_URL",
        "value": "${public_url}"
      },
      {
        "name": "APPCONFIG_SOLR_URL",
        "value": "${solr_url}"
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
        "name": "TZ",
        "value": "${timezone}"
      }
    ],
    "secrets": [
      {
        "name": "APPCONFIG_DB_URL",
        "valueFrom": "${db_url}"
      }
    ],
    "mountPoints": [
      {
        "sourceVolume": "${app_data}",
        "containerPath": "/archivesspace/data"
      }
    ],
    "dependsOn": [
      {
        "containerName": "createdb",
        "condition": "COMPLETE"
      },
      {
        "containerName": "solr",
        "condition": "START"
      }
    ],
    %{ if network_mode != "awsvpc" }
    "links": [
      "solr"
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
    "name": "solr",
    "image": "${solr_img}",
    "networkMode": "${network_mode}",
    "essential": true,
    "command": ["solr-create", "-p", "8983", "-c", "archivesspace", "-d", "archivesspace"],
    "environment": [
      {
        "name": "SOLR_JAVA_MEM",
        "value": "-Xms${solr_memory}m -Xmx${solr_memory}m"
      }
    ],
    "mountPoints": [
      {
        "sourceVolume": "${solr_data}",
        "containerPath": "/var/solr"
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
