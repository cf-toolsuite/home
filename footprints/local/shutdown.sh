#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
    echo "Usage: ./shutdown.sh toolsuite"
    exit 1
fi

suffix="${1:-toolsuite}"

export DOCKER_IP="host.docker.internal"

os=$(uname)
if [[ "$os" == *"Linux"* ]]; then
  export DOCKER_IP="172.17.0.1"
fi

# Change directories
cd docker

# Remove existing containers
docker compose -f docker-compose.yml -f docker-compose-"$suffix.yml" down

# Additional cleanup
docker image prune -f
docker volume prune -f
docker network prune -f
