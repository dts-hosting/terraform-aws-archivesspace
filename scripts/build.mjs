#!/usr/bin/env node
// Build and publish the multi-architecture aspace-proxy image.
//
// Always builds linux/amd64 + linux/arm64 with Docker Buildx and pushes.
// Set ASPACE_PROXY_ECR_IMG to also tag/push to ECR (see docker/README.md).
import { spawnSync } from "node:child_process";

const ecrImg = process.env.ASPACE_PROXY_ECR_IMG;
const platforms = process.env.ASPACE_PROXY_PLATFORMS ?? "linux/amd64,linux/arm64";

const tags = ["-t", "lyrasis/aspace-proxy:latest"];
if (ecrImg) {
  tags.push("-t", ecrImg);
} else {
  console.log("ASPACE_PROXY_ECR_IMG not set, skipping push to ECR");
}

const args = ["buildx", "build", "--platform", platforms, ...tags, "--push", "docker"];

console.log(`docker ${args.join(" ")}`);
const result = spawnSync("docker", args, { stdio: "inherit" });

if (result.error) {
  console.error(result.error.message);
  process.exit(1);
}
process.exit(result.status ?? 1);
