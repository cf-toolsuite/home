#!/usr/bin/env bash

set -e

# This script exposes a curated set of Spring Boot actuator endpoints and restages the target application

if [ -z "$1" ]; then
  echo "Usage: expose-actuator-endpoints.sh {application-name}"
  exit 1
fi

APP_NAME="$1"

cf set-env $APP_NAME MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE "info,jars,health,heapdump,pom,threaddump,metrics,scheduledtasks,loggers,mappings,prometheus"
cf restage $APP_NAME

