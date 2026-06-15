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

```bash
./build_and_push.sh
```

To also push to ECR install the [ecr credentials helper](https://github.com/awslabs/amazon-ecr-credential-helper?tab=readme-ov-file#installing).

Then set these envvars:

```
aws ecr get-login-password --region us-west-2 --profile archivesspace \
  | docker login --username AWS --password-stdin 513816696638.dkr.ecr.us-west-2.amazonaws.com \
&& docker build --no-cache -t 513816696638.dkr.ecr.us-west-2.amazonaws.com/archivesspace:proxy . \
&& docker push 513816696638.dkr.ecr.us-west-2.amazonaws.com/archivesspace:proxy
```
