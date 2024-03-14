#!/usr/bin/env bash

set -e

suffix="${1:-toolsuite}"

export DOCKER_IP="host.docker.internal"

os=$(uname)
if [[ "$os" == *"Linux"* ]]; then
  export DOCKER_IP="172.17.0.1"
fi

# Change directories
cd docker

# Display status of cluster
docker compose -f docker-compose.yml -f docker-compose-"$suffix.yml" ps -a
