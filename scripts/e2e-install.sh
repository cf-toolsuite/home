#!/usr/bin/env bash

set -e

# This script installs an opinionated footprint of cf-toolsuite services

ORG_HOME=observability
SPACE_HOME=cf-toolsuite

function determine_jar_release() {
  local date_pattern='[0-9]{4}\.[0-9]{2}\.[0-9]{2}'
  local date=""
  local current_date=""

  for file in target/*.jar; do
    if [[ $file =~ $date_pattern ]]; then
      current_date="${BASH_REMATCH[0]}"
      if [[ -z $date ]]; then
        date="$current_date"
      elif [[ $date != "$current_date" ]]; then
        echo "Varying dates found."
        return 1
      fi
    else
      echo "No matching date found in: $file"
      return 1
    fi
  done

  if [[ -n $date ]]; then
    echo $date
  else
    echo "No files with the expected date pattern found."
    return 1
  fi
}

# Define a function that checks for the existence of a file within the 'target' sub-directory.
# The function takes one parameter: the first few characters of a filename.
file_exists() {
  local starts_with=$1
  local search_pattern="./target/${starts_with}-1.0-SNAPSHOT.jar"

  # Use find command to search for files matching the pattern
  files_found=$(find . -wholename "$search_pattern")

  # Check if the find command's result is non-empty
  if [[ -n $files_found ]]; then
    return 0
  else
    return 1
  fi
}

# clones the repo if it doesn't exist
function clone_repo() {
  local repo="$1"
  name=$(echo "$repo" | cut -d '/' -f 2)
  if [ ! -d "$name" ]; then
    gh repo clone "$repo"
  else
    echo "$repo already exists, skipping clone..."
  fi
}

# forks then clones the repo if it doesn't exist
function fork_clone_repo() {
  local repo="$1"
  local fork_name="$2"
  name=$(echo "$fork_name" | cut -d '/' -f 2)
  if [ ! -d "$name" ]; then
    gh repo fork "$repo" --fork-name "$fork_name" --clone --remote
  else
    echo "$repo already exists, skipping fork and clone..."
  fi
}

echo "-- Starting installation"

# Create configuration directory

mkdir -p /tmp/config

# Install cf-toolsuite to a target foundation

if [ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ]; then
	echo "Usage: e2e-install.sh {cf-api} {cf-admin-username} {cf-admin-password} {clone-projects} {build-projects} {mode} {config-suffix} {gateway-deployed}"
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
GATEWAY_DEPLOYED="${8:-false}"

echo "-- Verify required configuration files exist"

if [ ! -e "/tmp/config/secrets.cf-butler.$SUFFIX.json" ] || [ ! -e "/tmp/config/secrets.cf-archivist.$SUFFIX.json" ]; then
  echo "Required configuration files missing!  Please place secrets.cf-butler.$SUFFIX.json and secrets.cf-archivist.$SUFFIX.json inside the /tmp/config directory.  Then attempt to re-run this script."
  echo "If you haven't created these files yet, look in the footprints/tas/config directory for inspiration."
  exit 1
fi

echo "-- Setting API endpoint for target foundation"

cf api "$CF_API"

echo "-- Authenticating"

if [ "$CF_ADMIN" = "sso" ]; then
  cf login --sso
else
  cf login -u "$CF_ADMIN" -p "$CF_PASSWORD"
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
  clone_repo 'cf-toolsuite/cf-butler'
  fork_clone_repo 'cf-toolsuite/cf-butler-sample-config' 'cf-butler-config'
  clone_repo 'cf-toolsuite/cf-hoover'
  fork_clone_repo 'cf-toolsuite/cf-hoover-config' 'cf-hoover-config'
  clone_repo 'cf-toolsuite/cf-hoover-ui'
  clone_repo 'cf-toolsuite/cf-archivist'
  fork_clone_repo 'cf-toolsuite/cf-archivist-sample-config' 'cf-archivist-config'
fi

if [ "$BUILD_PROJECTS" == "true" ]; then
  echo "-- Building applications"

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
else
  echo "-- Verifying artifacts exist"
  if [ "$MODE" == "butler-only" ] || [ "$MODE" == "full-install" ]; then
    cd cf-butler
    if file_exists "cf-butler"; then
      echo "+- cf-butler artifact exists!"
    else
      echo "+- Fetching latest available cf-butler artifact from Github Packages repository"
      mkdir -p target
      gh release download --pattern '*.jar' -D target --skip-existing
      RELEASE=$(determine_jar_release)
      sed -i'' -e "s/1.0-SNAPSHOT/$RELEASE/g" manifest.yml
    fi
    cd ..
  fi

  if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
    cd cf-hoover
    if file_exists "cf-hoover"; then
      echo "+- cf-hoover artifact exists!"
    else
      echo "+- Fetching latest available cf-hoover artifact from Github Packages repository"
      mkdir -p target
      gh release download --pattern '*.jar' -D target --skip-existing
      RELEASE=$(determine_jar_release)
      sed -i'' -e "s/1.0-SNAPSHOT/$RELEASE/g" manifest.yml
      sed -i'' -e "s/1.0-SNAPSHOT/$RELEASE/g" manifest.with-registry.yml
    fi
    cd ..
  fi

  if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
    cd cf-hoover-ui
    if file_exists "cf-hoover-ui"; then
      echo "+- cf-hoover-ui artifact exists!"
    else
      echo "+- Fetching latest available cf-hoover-ui artifact from Github Packages repository"
      mkdir -p target
      gh release download --pattern '*.jar' -D target --skip-existing
      RELEASE=$(determine_jar_release)
      sed -i'' -e "s/1.0-SNAPSHOT/$RELEASE/g" manifest.yml
    fi
    cd ..
  fi

  if [ "$MODE" == "archivist-only" ] || [ "$MODE" == "full-install" ]; then
    cd cf-archivist
    if file_exists "cf-archivist"; then
      echo "+- cf-archivist artifact exists!"
    else
      echo "+- Fetching latest available cf-archivist artifact from Github Packages repository"
      mkdir -p target
      gh release download --pattern '*.jar' -D target --skip-existing
      RELEASE=$(determine_jar_release)
      sed -i'' -e "s/1.0-SNAPSHOT/$RELEASE/g" manifest.yml
    fi
    cd ..
  fi
fi

echo "-- Deploying applications"

if [ "$MODE" == "butler-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-butler
  if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
    ./scripts/deploy.alt.sh --with-credhub /tmp/config/secrets.cf-butler.$SUFFIX.json --no-route
    cf map-route cf-butler apps.internal --hostname cf-butler
  else
    ./scripts/deploy.alt.sh --with-credhub /tmp/config/secrets.cf-butler.$SUFFIX.json
  fi
  cd ..
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-hoover-config
  # Get the repository URL using `git remote get-url`
  repository_url=$(git remote get-url origin)
  # Extract the owner from the repository URL (SSH or https)
  owner=$(echo "$repository_url" | sed -nr 's/.*github.com[\/:](.*)\/.*/\1/p')

  cd ../cf-hoover
  mkdir -p config
  cp -f samples/config-server.json config

  sed -i'' -e "s/cf-toolsuite/$owner/g" "config/config-server.json"

  if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
    ./scripts/deploy.with-registry.sh --no-route
    cf map-route cf-hoover apps.internal --hostname cf-hoover
  else
    ./scripts/deploy.with-registry.sh
  fi
  cd ..
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-hoover-ui
  if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
    ./scripts/deploy.sh --no-route
    cf map-route cf-hoover-ui apps.internal --hostname cf-hoover-ui
  else
    ./scripts/deploy.sh
  fi
  cd ..
fi

if [ "$MODE" == "archivist-only" ] || [ "$MODE" == "full-install" ]; then
  cd cf-archivist
  if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
    ./scripts/deploy.alt.sh --with-credhub /tmp/config/secrets.cf-archivist.$SUFFIX.json --no-route
    cf map-route cf-archivist apps.internal --hostname cf-archivist
  else
    ./scripts/deploy.alt.sh --with-credhub /tmp/config/secrets.cf-archivist.$SUFFIX.json
  fi
  cd ..
fi

if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
  GW_NAME=cf-toolsuite
  cf create-service p.gateway standard $GW_NAME -c "{ \"host\": \"$GW_NAME\" }"
  for (( i = 0; i < 90; i++ )); do
    if [[ $(cf service $GW_NAME) != *"succeeded"* ]]; then
      echo "$GW_NAME is not ready yet..."
      sleep 10
    else
      break
    fi
  done

  if [ "$MODE" == "butler-only" ] || [ "$MODE" == "full-install" ]; then
    cf bind-service cf-butler $GW_NAME -c .gw-butler.json
    cf restage cf-butler
  fi
  if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
    cf bind-service cf-hoover $GW_NAME -c .gw-hoover.json
    cf restage cf-hoover
    cf bind-service cf-hoover-ui $GW_NAME -c .gw-hoover-ui.json
    cf restage cf-hoover-ui
  fi
  if [ "$MODE" == "archivist-only" ] || [ "$MODE" == "full-install" ]; then
    cf bind-service cf-archivist $GW_NAME -c .gw-archivist.json
    cf restage cf-archivist
  fi
fi

echo "-- Completed installation"
