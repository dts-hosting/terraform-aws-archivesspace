# ArchivesSpace services

Configuration in this directory creates an ArchivesSpace deployment
using pre-existing service dependencies (vpc, db, alb etc.).

*Note: this example is used for internal testing and is not
intended for general use other than as a reference.*

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Without a `terraform.tfvars` file the deployment will use the
default configuration (c.f. hosting repository).

This will create:

- https://archivesspace-services-pui.lyrtech.org
- https://archivesspace-services-sui.lyrtech.org

### Override configuration

Optionally create `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update the values as appropriate:

- `cluster_name`
  - the name of an existing ECS cluster
- `db_*`
  - valid db parameters, including existing SSM param names
- `domain`
  - this is the domain to use for public DNS
  - you must have a Route53 hosted zone available for this domain
- `efs_name`
  - the name of an existing EFS
- `lb_name`
  - the name of an existing ALB
- `security_group_name`
  - the name of an existing security group
- `subnet_type`
  - the type (by tag) of existing subnets
- `vpc_name`
  - the name of an existing vpc
