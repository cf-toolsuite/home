#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
    echo "Usage: ./startup.sh toolsuite"
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

# Start the config services first and wait for them to become available
docker compose up -d butler-config-service
docker compose up -d archivist-config-service

while [ -z "$CONFIG_SERVICE_READY" ]; do
  echo "Waiting for cf-butler config service..."
  if [ "$(curl --silent "$DOCKER_IP":8888/actuator/health 2>&1 | grep -q '\"status\":\"UP\"'; echo $?)" = 0 ]; then
      CONFIG_SERVICE_READY=true;
  fi
  sleep 5
done

while [ -z "$CONFIG_SERVICE_READY" ]; do
  echo "Waiting for cf-archivist config service..."
  if [ "$(curl --silent "$DOCKER_IP":8889/actuator/health 2>&1 | grep -q '\"status\":\"UP\"'; echo $?)" = 0 ]; then
      CONFIG_SERVICE_READY=true;
  fi
  sleep 5
done

# Start the discovery service next and wait
docker compose up -d discovery-service

while [ -z "$DISCOVERY_SERVICE_READY" ]; do
  echo "Waiting for discovery service..."
  if [ "$(curl --silent "$DOCKER_IP":8761/actuator/health 2>&1 | grep -q '\"status\":\"UP\"'; echo $?)" = 0 ]; then
      DISCOVERY_SERVICE_READY=true;
  fi
  sleep 5
done

# Start the other containers
docker compose -f docker-compose.yml -f docker-compose-"$suffix.yml" up -d

cd ..

# Attach to the log output of the cluster
./show-log.sh "$suffix"

# Display status of cluster
./status.sh "$suffix"