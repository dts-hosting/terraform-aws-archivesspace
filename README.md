# ArchivesSpace Terraform module

Run ArchivesSpace as an ECS service using an all-inclusive
task definition:

- MySQL cli for creating the database
- Nginx proxy for routing to ArchivesSpace endpoints
- ArchivesSpace with EFS for persistence (`/archivesspace/data`)

## Usage

See the examples for deployment options:

- [services: configures the module using references to pre-existing resources](./examples/services/README.md)

## Notable configuration details

### Custom environment and secrets configuration

Custom (non-predefined) environment and secrets configuration can be defined:

```hcl
custom_env_cfg = {
  "APPCONFIG_BACKEND_LOG_LEVEL" = "info"
}
custom_secrets_cfg = {
  "ASPACE_SECRET_KEY" = "arn:aws:ssm:us-east-2:111222333444:parameter/ASpaceSecretKey"
}
```

### Launch type

To deploy to an ECS/EC2 auto-scaling group:

```ini
capacity_provider        = "EC2"
network_mode             = "bridge"
requires_compatibilities = ["EC2"]
target_type              = "instance"
```

To deploy to an ECS/EC2 auto-scaling group with `awsvpc` network mode:

```ini
capacity_provider        = "EC2"
network_mode             = "awsvpc"
requires_compatibilities = ["EC2"]
target_type              = "ip"
```

To deploy to Fargate (the default):

```ini
capacity_provider        = "FARGATE"
network_mode             = "awsvpc"
requires_compatibilities = ["FARGATE"]
target_type              = "ip"
```

### CPU architecture

`cpu_architecture` defaults to `null`, which omits the `runtime_platform` block
from the task definition. This keeps existing deployments unchanged and lets an
ECS/EC2 capacity provider select the matching image from a multiarch repo based
on the container instance type — Graviton instances pull `arm64`, x86 instances
pull `amd64`, with no explicit configuration. On Fargate, an unset architecture
defaults to `X86_64`.

To pin the architecture explicitly:

```hcl
cpu_architecture = "ARM64"
```

Valid values are `X86_64` and `ARM64`. Setting this is typically only needed to
run on ARM64 under Fargate (use Linux platform version `1.4.0` or later); for
ECS/EC2, prefer leaving it unset so instance type drives image selection.

### Listeners

The `https_listener_arn` routes traffic to ArchivesSpace.

### Resource allocations

#### Cpu

```hcl
cpu = 1024 # 1 v/cpu default
cpu = null # don't set a cpu constraint
```

#### Memory

```hcl
app_memory  = 2048 # specific allocation to the aspace container
task_memory = 3072 # allocation for task (all containers)
```

When running on Fargate the `task_memory` needs to equal a [compatible value](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html).
