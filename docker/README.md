# Nginx proxy for ArchivesSpace

The Nginx proxy provides a single access point for routing to the
ArchivesSpace server applications. It can run in two modes:

- `single`
  - public and staff interfaces are available via the same hostname
- `multi`
  - public and staff interfaces are available via separate hostnames

## Test

```bash
docker compose build
docker compose up
UPSTREAM_HOST=app docker compose up
```

## Publish

From the repository root:

```bash
mise run build
```

The publish task uses Docker Buildx and always publishes a multi-architecture
image for `linux/amd64` and `linux/arm64`.

To also push to ECR you need the
[ecr credentials helper](https://github.com/awslabs/amazon-ecr-credential-helper),
which mise installs for you (`mise install`). Tell Docker to use it for the
registry by adding a `credHelpers` entry to `~/.docker/config.json`:

```json
{
  "credHelpers": {
    "513816696638.dkr.ecr.us-west-2.amazonaws.com": "ecr-login"
  }
}
```

Then set these envvars and run the build. The cross-platform way is a
`mise.local.toml` in the repository root (gitignored), which mise loads for
every task regardless of your shell:

```toml
[env]
AWS_PROFILE = "archivesspace" # set the profile name
ASPACE_PROXY_ECR_IMG = "513816696638.dkr.ecr.us-west-2.amazonaws.com/archivesspace:proxy" # set img
```

```bash
mise run build
```
