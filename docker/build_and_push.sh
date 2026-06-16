#!/bin/bash
set -euo pipefail

tags=(-t lyrasis/aspace-proxy:latest)

if [ -n "${ASPACE_PROXY_ECR_IMG:-}" ]; then
  tags+=(-t "$ASPACE_PROXY_ECR_IMG")
else
  echo "ASPACE_PROXY_ECR_IMG not set, skipping push to ECR"
fi

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  "${tags[@]}" \
  --push \
  .
