# ArchivesSpace Terraform module

Run ArchivesSpace as an ECS service using an all-inclusive
task definition:

- Nginx for http to https redirects and certbot (optional for SSL certs)
- MySQL cli for creating the database
- Nginx proxy for routing to ArchivesSpace endpoints
- ArchivesSpace with EFS for persistence (`/archivesspace/data`)
- Solr with EFS for persistence (`/var/solr`)

## Usage

TODO.

## Notable configuration details

### Launch type

To deploy to an ECS/EC2 auto-scaling group:

```hcl
capacity_provider        = "EC2"
network_mode             = "bridge"
requires_compatibilities = ["EC2"]
target_type              = "instance"
```

To deploy to Fargate (the default):

```hcl
capacity_provider        = "FARGATE"
network_mode             = "awsvpc"
requires_compatibilities = ["FARGATE"]
target_type              = "ip"
```

### Listeners

The module requires `http_listener_arn` for nginx to redirect http
requests to https. The latter container includes certbot for (optionally)
generating SSL certificates. The latter use case accounts for why
the http redirection is happening within a container rather than as
a listener rule.

The `https_listener_arn` routes traffic to ArchivesSpace.

The `listener_priority` acts as a kind of "id" for the instance.
The assigned priority is multiplied by 10 to create "space" for
assigning priorities to routes. Given `listener_priority = 1`:

```txt
certbot (* 10 + 0) = 10 (http listener)
proxy:  (* 10 + 1) = 11 (https listener)
```

This ensures that a single, unique `listener_priority` per instance
can create a deterministic priority assignment without conflicts
as instances are added, updated or removed.

Note: [priority has a maximum value of 50000](https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_CreateRule.html)

### Resource allocations

#### Cpu

This only applies to Fargate containers.

```hcl
cpu = 1024 # 1 v/cpu default
```

#### Memory

```hcl
app_memory  = 2048 # specific allocation to the aspace container
solr_memory = 1024 # specific allocation to the solr container
```

The task definition memory is set to (app_memory + solr_memory). When
running on Fargate this needs to equal a [compatible value](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html).
