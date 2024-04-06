#!/usr/bin/env bash

set -e

# This script:
#   stops the application
#   creates a MySQL backend in the target foundation organization and space
#   calls cf bind-service to bind it to a target application
#   rebuilds the application w/ the necessary provider dependency
#   pushes the application to the target foundation organization and space

# You should have access to the source of the application
# You should be aware of the cf marketplace service offerings to choose the correct/available service plan

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

if [ -z "$1" ] && [ -z "$2" ]; then
	echo "Usage: switch-backend-to-mysql.sh {cf-api} {cf-admin-username} {cf-admin-password} {application-name} {application-version} {mysql-service-plan} {path/to/application/source} {build-project}"
	exit 1
fi

# e.g.,
# Default target, Dhaka:  ./scripts/switch-backend-to-mysql.sh api.sys.dhaka.cf-app.com sso ' '
# Alternate foundation:  ./scripts/switch-backend-to-mysql.sh api.sys.orca-916168.cf-app.com username 'password'

CF_API="${1}"
CF_ADMIN="${2}"
CF_PASSWORD="${3}"
APP_NAME="${4:-cf-butler}"
APP_VERSION="${5:-1.0-SNAPSHOT}"
MYSQL_SERVICE_PLAN="${6:-db-medium-80}"
PATH_TO_SRC="${7:-/tmp/$APP_NAME}"
BUILD_PROJECT="${8:-true}"


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

echo "-- Stopping $APP_NAME"

cf stop $APP_NAME

echo "-- Creating a MySQL database instance"

cf create-service p.mysql $MYSQL_SERVICE_PLAN $APP_NAME-backend
while [[ $(cf service $APP_NAME-backend) != *"succeeded"* ]]; do
    echo "$APP_NAME-backend is not ready yet..."
    sleep 5s
done

echo "-- Binding $APP_NAME to $APP_NAME-backend"

cf bind-service $APP_NAME $APP_NAME-backend

echo "-- Rebuilding source with correct provider dependency"

cd $PATH_TO_SRC

if [ "$BUILD_PROJECT" == "true" ]; then
  ./mvnw clean package -Pmysql,expose-runtime-metadata
else
  echo "+- Fetching latest available $APP_NAME artifact from Github Packages repository"
  mkdir -p target
  gh release download --pattern '*.jar' -R cf-toolsuite/$APP_NAME -D target
  APP_VERSION=$(determine_jar_release)
fi

echo "-- Pushing $APP_NAME"

cf push -p target/$APP_NAME-mysql-$APP_VERSION.jar
