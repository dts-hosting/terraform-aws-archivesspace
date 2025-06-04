[
  {
    "name": "arclight",
    "image": "${img}",
    "networkMode": "${network_mode}",
    "essential": true,
    "environment": [
      {
        "name": "ARCLIGHT_SITE",
        "value": "${site}"
      },
      {
        "name": "RAILS_ASSUME_SSL",
        "value": "${rails_assume_ssl}"
      },
      {
        "name": "RAILS_ENV",
        "value": "${rails_env}"
      },
      {
        "name": "RAILS_FORCE_SSL",
        "value": "${rails_force_ssl}"
      },
      {
        "name": "RAILS_LOG_TO_STDOUT",
        "value": "${rails_log_to_stdout}"
      },
      {
        "name": "RAILS_SERVE_STATIC_FILES",
        "value": "${rails_serve_static_files}"
      },
      {
        "name": "SOLR_URL",
        "value": "${solr_url}"
      }
    ],
    "secrets": [
      {
        "name": "SECRET_KEY_BASE",
        "valueFrom": "${secret_key_base}"
      }
    ],
    "portMappings": [
      {
        "containerPort": ${port}
      }
    ],
    %{ if capacity_provider == "EC2" }
    "linuxParameters": {
        "maxSwap": ${swap_size},
        "swappiness": 60
    },
    %{ endif ~}
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "arclight"
      }
    }
  }
]
