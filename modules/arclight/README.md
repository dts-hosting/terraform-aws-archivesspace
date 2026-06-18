# Arclight module

## CPU architecture

`cpu_architecture` defaults to `null`, which omits the `runtime_platform`
block from the task definition. This leaves existing deployments unchanged and
lets ECS/EC2 capacity providers select the matching image from a multiarch repo
based on the container instance type (e.g. pulling `arm64` on Graviton). On
Fargate, an unset architecture defaults to `X86_64`.

To pin the architecture (required to run ARM64 on Fargate):

```hcl
cpu_architecture = "ARM64"
```

Valid values are `X86_64` and `ARM64`.
