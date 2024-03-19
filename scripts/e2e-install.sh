#!/usr/bin/env bash

set -e

# This script installs an opinionated footprint of cf-toolsuite services

ORG_HOME=observability
SPACE_HOME=cf-toolsuite

echo "-- Starting installation"

# Create configuration directory

mkdir -p /tmp/config

# Install cf-toolsuite to a target foundation

if [ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ]; then
	echo "Usage: e2e-install.sh {cf-api} {cf-admin-username} {cf-admin-password} {clone-projects} {build-projects} {mode} {config-suffix}"
	exit 1
fi

# e.g.,
# Default target, Dhaka:  ./scripts/e2e-install.sh api.sys.dhaka.cf-app.com sso ' '
# Alternate foundation:  ./scripts/e2e-install.sh api.sys.orca-916168.cf-app.com username 'password' true true full-install orca

CF_API="${1}"
CF_ADMIN="${2}"
CF_PASSWORD="${3}"
CLONE_PROJECTS="${4:-true}"
BUILD_PROJECTS="${5:-true}"
MODE="${6:-full-install}"
SUFFIX="${7:-dhaka}"

echo "-- Verify required configuration files exist"

if [ ! -e "/tmp/config/secrets.cf-butler.$SUFFIX.json" ] || [ ! -e "/tmp/config/secrets.cf-archivist.$SUFFIX.json" ]; then
  echo "Required configuration files missing!  Please place secrets.cf-butler.$SUFFIX.json and secrets.cf-archivist.$SUFFIX.json inside the /tmp/config directory.  Then attempt to re-run this script."
  exit 1
fi

echo "-- Setting API endpoint for target foundation"

cf api $CF_API

echo "-- Authenticating"

if [ "$CF_ADMIN" = "sso" ]; then
  cf login --sso
else
  cf login -u $CF_ADMIN -p $CF_PASSWORD
fi

echo "-- Creating organization and space"
# Make sure org quota is set to support something like:

# ❯ cf org-quota runaway
# Getting org quota runaway as chris.phillipson...

# total memory:            100G
# instance memory:         unlimited
# routes:                  1000
# service instances:       unlimited
# paid service plans:      allowed
# app instances:           unlimited
# route ports:             0
# log volume per second:   unlimited

cf create-org $ORG_HOME
cf create-space -o $ORG_HOME $SPACE_HOME

echo "-- Targeting organization and space"

cf target -o $ORG_HOME -s $SPACE_HOME

cd /tmp


if [ "$CLONE_PROJECTS" == "true" ]; then
  echo "-- Cloning Github repositories"
  gh repo clone cf-toolsuite/spring-boot-starter-runtime-metadata
  gh repo clone cf-toolsuite/cf-butler
  gh repo fork cf-toolsuite/cf-butler-sample-config --fork-name cf-butler-config --clone --remote
  gh repo clone cf-toolsuite/cf-hoover
  gh repo fork cf-toolsuite/cf-hoover-config --clone --remote
  gh repo clone cf-toolsuite/cf-hoover-ui
  gh repo clone cf-toolsuite/cf-archivist
  gh repo fork cf-toolsuite/cf-archivist-sample-config --fork-name cf-archivist-config --clone --remote
fi

if [ "$BUILD_PROJECTS" == "true" ]; then
  echo "-- Building library and applications"

  cd spring-boot-starter-runtime-metadata
  ./mvnw clean install
  cd ..

  if [ "$MODE" == "butler-only" ] || [ "$MODE" == "full-install" ]; then
    cd cf-butler
    ./mvnw clean package -Ph2,expose-runtime-metadata
    cd ..
  fi

  if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
    cd cf-hoover
    ./mvnw clean package -Pexpose-runtime-metadata
    cd ..
  fi

  if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
    cd cf-hoover-ui
    ./mvnw clean verify --batch-mode -DskipTests -Pproduction,expose-runtime-metadata
    cd ..
  fi

  if [ "$MODE" == "archivist-only" ] || [ "$MODE" == "full-install" ]; then
    cd cf-archivist
    ./mvnw clean verify --batch-mode -DskipTests -Pproduction,expose-runtime-metadata
    cd ..
  fi
fi

echo "-- Deploying applications"

if [ "$MODE" == "butler-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-butler
  ./scripts/deploy.alt.sh --with-credhub /tmp/config/secrets.cf-butler.$SUFFIX.json
  cd ..
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-hoover
  mkdir -p config
  cp -f samples/config-server.json config
  # Get the repository URL using `git remote get-url`
  repository_url=$(git remote get-url origin)
  # Extract the owner from the repository URL
  owner=$(echo "$repository_url" | cut -d'/' -f4)
  sed -i "s/cf-toolsuite/$owner/g" "config/config-server.json"
  ./scripts/deploy.with-registry.sh
  cd ..
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-hoover-ui
  ./scripts/deploy.sh
  cd ..
fi

if [ "$MODE" == "archivist-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-archivist
  ./scripts/deploy.alt.sh --with-credhub /tmp/config/secrets.cf-archivist.$SUFFIX.json
  cd ..
fi

echo "-- Completed installation"
