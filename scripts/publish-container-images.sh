#!/usr/bin/env bash

set -e

# This script will build and publish container images to Github Container Registry using the pack CLI, one for each service in cf-toolsuite
# @see https://paketo.io/docs/howto/java/

CLONE_PROJECTS="${1:-false}"
MODE="${2:-full-install}"
DOCKER_HOST="${3:-docker.io}"
DOCKER_USERNAME="${4:-cftoolsuite}"
DOCKER_PASSWORD="${5}"
IMAGE_TAG=$(date '+%Y.%m.%d')

cd /tmp

if [ "$CLONE_PROJECTS" == "true" ]; then
  echo "-- Cloning Github repositories"
  gh repo clone cf-toolsuite/spring-boot-starter-runtime-metadata
  gh repo clone cf-toolsuite/cf-butler
  gh repo clone cf-toolsuite/cf-hoover
  gh repo clone cf-toolsuite/cf-hoover-ui
  gh repo clone cf-toolsuite/cf-archivist
  gh repo clone cf-toolsuite/home
fi

echo "-- Building spring-boot-starter-runtime-metadata"

cd spring-boot-starter-runtime-metadata
./mvnw clean install
cd ..

echo "-- Authenticating (${DOCKER_HOST})"

docker login ${DOCKER_HOST} -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}

echo "-- Building and publishing container images"

if [ "$MODE" == "butler-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-butler
  pack build ${DOCKER_HOST}/cftoolsuite/cf-butler:$IMAGE_TAG \
    --tag ${DOCKER_HOST}/cftoolsuite/cf-butler:latest \
    --path . \
    --env BP_MAVEN_ACTIVE_PROFILES=mysql,expose-runtime-metadata \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-full \
    --volume $HOME/.m2:/home/cnb/.m2:rw \
    --publish
  cd ..
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-hoover
  pack build ${DOCKER_HOST}/cftoolsuite/cf-hoover:$IMAGE_TAG \
    --tag ${DOCKER_HOST}/cftoolsuite/cf-butler:latest \
    --path . \
    --env BP_MAVEN_ACTIVE_PROFILES=expose-runtime-metadata \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-full \
    --volume $HOME/.m2:/home/cnb/.m2:rw \
    --publish
  cd ..
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-hoover-ui
  pack build ${DOCKER_HOST}/cftoolsuite/cf-hoover-ui:$IMAGE_TAG \
    --tag ${DOCKER_HOST}/cftoolsuite/cf-butler:latest \
    --path . \
    --env BP_MAVEN_BUILD_ARGUMENTS="clean verify --batch-mode -DskipTests" \
    --env BP_MAVEN_ACTIVE_PROFILES=production,expose-runtime-metadata \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-full \
    --volume $HOME/.m2:/home/cnb/.m2:rw \
    --publish
  cd ..
fi

if [ "$MODE" == "archivist-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-archivist
  pack build ${DOCKER_HOST}/cftoolsuite/cf-archivist:$IMAGE_TAG \
    --tag ${DOCKER_HOST}/cftoolsuite/cf-butler:latest \
    --path . \
    --env BP_MAVEN_BUILD_ARGUMENTS="clean verify --batch-mode -DskipTests" \
    --env BP_MAVEN_ACTIVE_PROFILES=mysql,production,expose-runtime-metadata \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-full \
    --volume $HOME/.m2:/home/cnb/.m2:rw \
    --publish
  cd ..
fi

cd home/footprints/local/support
./mvnw -pl . -am clean install
cd ../../../../

if [ "$MODE" == "support-only" ] || [ "$MODE" == "full-install" ]; then
  cd home/footprints/local/support/config-server
  pack build ${DOCKER_HOST}/cftoolsuite/config-server:$IMAGE_TAG \
    --tag ${DOCKER_HOST}/cftoolsuite/cf-butler:latest \
    --path . \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-full \
    --volume $HOME/.m2:/home/cnb/.m2:rw \
    --publish
  cd ../../../../../
fi

if [ "$MODE" == "support-only" ] || [ "$MODE" == "full-install" ]; then
  cd home/footprints/local/support/discovery-service
  pack build ${DOCKER_HOST}/cftoolsuite/discovery-service:$IMAGE_TAG \
    --tag ${DOCKER_HOST}/cftoolsuite/cf-butler:latest \
    --path . \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-full \
    --volume $HOME/.m2:/home/cnb/.m2:rw \
    --publish
  cd ../../../../../
fi

if [ "$MODE" == "support-only" ] || [ "$MODE" == "full-install" ]; then
  cd home/footprints/local/support/microservices-console
  pack build ${DOCKER_HOST}/cftoolsuite/microservices-console:$IMAGE_TAG \
    --tag ${DOCKER_HOST}/cftoolsuite/cf-butler:latest \
    --path . \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-full \
    --volume $HOME/.m2:/home/cnb/.m2:rw \
    --publish
  cd ../../../../../
fi

echo "-- Completed building and publishing container images"