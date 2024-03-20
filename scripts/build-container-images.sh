#!/usr/bin/env bash

set -e

# This script will build container images using the pack CLI, one for each service in cf-toolsuite
# @see https://paketo.io/docs/howto/java/

CLONE_PROJECTS="${1:-false}"
MODE="${2:-full-install}"


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

echo "-- Building container images"

if [ "$MODE" == "butler-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-butler
  pack build cftoolsuite/cf-butler \
    --path . \
    --env BP_MAVEN_ACTIVE_PROFILES=mysql,expose-runtime-metadata \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-tiny \
    --volume $HOME/.m2:/home/cnb/.m2:rw
  cd ..
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-hoover
  pack build cftoolsuite/cf-hoover \
    --path . \
    --env BP_MAVEN_ACTIVE_PROFILES=expose-runtime-metadata \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-tiny \
    --volume $HOME/.m2:/home/cnb/.m2:rw
  cd ..
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-hoover-ui
  pack build cftoolsuite/cf-hoover-ui \
    --path . \
    --env BP_MAVEN_BUILD_ARGUMENTS="clean verify --batch-mode -DskipTests" \
    --env BP_MAVEN_ACTIVE_PROFILES=production,expose-runtime-metadata \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-tiny \
    --volume $HOME/.m2:/home/cnb/.m2:rw
  cd ..
fi

if [ "$MODE" == "archivist-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-archivist
  pack build cftoolsuite/cf-archivist \
    --path . \
    --env BP_MAVEN_BUILD_ARGUMENTS="clean verify --batch-mode -DskipTests" \
    --env BP_MAVEN_ACTIVE_PROFILES=mysql,production,expose-runtime-metadata \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-tiny \
    --volume $HOME/.m2:/home/cnb/.m2:rw
  cd ..
fi

cd home/footprints/local/support
./mvnw -pl . -am clean install
cd ../../../../

if [ "$MODE" == "support-only" ] || [ "$MODE" == "full-install" ]; then
  cd home/footprints/local/support/config-server
  pack build cftoolsuite/config-server \
    --path . \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-tiny \
    --volume $HOME/.m2:/home/cnb/.m2:rw
  cd ../../../../../
fi

if [ "$MODE" == "support-only" ] || [ "$MODE" == "full-install" ]; then
  cd home/footprints/local/support/discovery-service
  pack build cftoolsuite/discovery-service \
    --path . \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-tiny \
    --volume $HOME/.m2:/home/cnb/.m2:rw
  cd ../../../../../
fi

if [ "$MODE" == "support-only" ] || [ "$MODE" == "full-install" ]; then
  cd home/footprints/local/support/microservices-console
  pack build cftoolsuite/microservices-console \
    --path . \
    --env BP_JVM_VERSION=21.* \
    --builder paketobuildpacks/builder-jammy-tiny \
    --volume $HOME/.m2:/home/cnb/.m2:rw
  cd ../../../../../
fi

echo "-- Completed building container images"