#!/usr/bin/env bash

set -e

# This script uninstalls the opinionated footprint of cf-toolsuite services

ORG_HOME=observability
SPACE_HOME=cf-toolsuite

echo "-- Starting teardown"

# Install cf-toolsuite to a target foundation

if [ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ]; then
	echo "Usage: e2e-install.sh {cf-api} {cf-admin-username} {cf-admin-password} {mode} {gateway-deployed}"
	exit 1
fi

# e.g.,
# Default target, Dhaka:  ./scripts/e2e-install.sh api.sys.dhaka.cf-app.com sso ' '
# Alternate foundation:  ./scripts/e2e-install.sh api.sys.orca-916168.cf-app.com username 'password' true true full-install orca

CF_API="${1}"
CF_ADMIN="${2}"
CF_PASSWORD="${3}"
MODE="${4:-full-install}"
GATEWAY_DEPLOYED="${5:-false}"
GW_NAME=cf-toolsuite


echo "-- Setting API endpoint for target foundation"

cf api $CF_API

echo "-- Authenticating"

if [ "$CF_ADMIN" = "sso" ]; then
  cf login --sso
else
  cf login -u $CF_ADMIN -p $CF_PASSWORD
fi

echo "-- Targeting organization and space"

cf target -o $ORG_HOME -s $SPACE_HOME


echo "-- Deploying applications"

if [ "$MODE" == "butler-only" ] || [ "$MODE" == "full-install" ]; then
  if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
    cf us cf-butler $GW_NAME
  fi
  cf us cf-butler cf-butler-secrets
  cf ds cf-butler-secrets -f
  cf d cf-butler -r -f
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
    cf us cf-hoover $GW_NAME
  fi
  cf us cf-hoover hooverRegistry
  cf us cf-hoover cf-hoover-config
  cf d cf-hoover -r -f
fi

if [ "$MODE" == "hoover-only" ] || [ "$MODE" == "full-install" ]; then
  if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
    cf us cf-hoover-ui $GW_NAME
  fi
  cf us cf-hoover-ui hooverRegistry
  cf d cf-hoover-ui -r -f
  cf ds cf-hoover-config -f
  cf ds hooverRegistry -f
fi

if [ "$MODE" == "archivist-only" ] || [ "$MODE" == "full-install" ]; then
  if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
    cf us cf-archivist $GW_NAME
  fi
  cf us cf-archivist cf-archivist-secrets
  cf ds cf-archivist-secrets -f
  cf d cf-archivist -r -f
fi

if [[ "$GATEWAY_DEPLOYED" == "true" ]]; then
  cf ds $GW_NAME -f
fi

cf delete-space $SPACE_HOME
cf delete-org $ORG_HOME

echo "-- Completed teardown"
