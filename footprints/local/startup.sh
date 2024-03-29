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

# Start prometheus and wait for it to become available
docker compose up -d prometheus

while [ -z "$PROMTHEUS_READY" ]; do
  echo "Waiting for prometheus to become healthy..."
  if [ "$(curl --silent "$DOCKER_IP":9090/-/healthy 2>&1 | grep -q 'Prometheus Server is Healthy'; echo $?)" = 0 ]; then
      PROMTHEUS_READY=true;
  fi
  sleep 5
done

# Start the config service second and wait for it to become available
docker compose up -d config-service

while [ -z "$CONFIG_SERVICE_READY" ]; do
  echo "Waiting for cf-hoover config service to become healthy..."
  if [ "$(curl --silent "$DOCKER_IP":8888/actuator/health 2>&1 | grep -q '\"status\":\"UP\"'; echo $?)" = 0 ]; then
      CONFIG_SERVICE_READY=true;
  fi
  sleep 5
done

# Start the discovery service next and wait
docker compose up -d discovery-service

while [ -z "$DISCOVERY_SERVICE_READY" ]; do
  echo "Waiting for discovery service to become healthy..."
  if [ "$(curl --silent "$DOCKER_IP":8761/actuator/health 2>&1 | grep -q '\"status\":\"UP\"'; echo $?)" = 0 ]; then
      DISCOVERY_SERVICE_READY=true;
  fi
  sleep 5
done

# Start remaining infra services
docker compose up -d

# Start butler and wait
docker compose -f docker-compose.yml -f docker-compose-"$suffix.yml" up -d butler

while [ -z "$BUTLER_READY" ]; do
  echo "Waiting for cf-butler to become healthy..."
  if [ "$(curl --silent "$DOCKER_IP":8080/actuator/health 2>&1 | grep -q '\"status\":\"UP\"'; echo $?)" = 0 ]; then
      BUTLER_READY=true;
  fi
  sleep 5
done

# Start hoover and wait
docker compose -f docker-compose.yml -f docker-compose-"$suffix.yml" up -d hoover

while [ -z "$HOOVER_READY" ]; do
  echo "Waiting for cf-hoover to become healthy..."
  if [ "$(curl --silent "$DOCKER_IP":8082/actuator/health 2>&1 | grep -q '\"status\":\"UP\"'; echo $?)" = 0 ]; then
      HOOVER_READY=true;
  fi
  sleep 5
done

# Start the remaining cf-toolsuite services
docker compose -f docker-compose.yml -f docker-compose-"$suffix.yml" up -d

cd ..

# Attach to the log output of the cluster
./show-log.sh "$suffix"

# Display status of cluster
./status.sh "$suffix"