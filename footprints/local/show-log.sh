#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
    echo "Usage: ./show-log.sh toolsuite {service_name}"
    exit 1
fi

suffix="${1:-toolsuite}"
service_name="${2:-}"

export DOCKER_IP="host.docker.internal"

os=$(uname)
if [[ "$os" == *"Linux"* ]]; then
  export DOCKER_IP="172.17.0.1"
fi

# Change directories
cd docker

# Display logs for service in cluster
docker compose -f docker-compose.yml -f docker-compose-"$suffix.yml" logs $service_name