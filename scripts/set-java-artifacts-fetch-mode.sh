#!/usr/bin/env bash

set -e

# This script sets the fetch mode and restages cf-butler

valid_options=("obtain-jars-from-runtime-metadata" "list-jars-in-droplet" "unpack-pom-contents-in-droplet")

if [ -z "$1" ]; then
  echo "Usage: set-java-artifacts-fetch-mode.sh [ obtain-jars-from-runtime-metadata | list-jars-in-droplet | unpack-pom-contents-in-droplet ]"
  exit 1
fi

# Get the input value
FETCH_MODE="$1"

# Check if the input value matches one of the valid options
if [[ " ${valid_options[@]} " =~ " $FETCH_MODE " ]]; then
  cf set-env cf-butler JAVA_ARTIFACTS_FETCH_MODE $1
  cf restage cf-butler
else
    echo "JAVA_ARTIFACTS_FETCH_MODE: '$FETCH_MODE' does not match any valid option.  Exiting."
    exit 1
fi
