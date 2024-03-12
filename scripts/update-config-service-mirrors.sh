#!/usr/bin/env bash

set -e

# For Spring Cloud Services configuration, when you make a change to a configuration property stored in a Git repository,
# you may need to update both the mirror used by the Config Server and the client application's local configuration.
# @see https://docs.vmware.com/en/Spring-Cloud-Services-for-VMware-Tanzu/3.2/spring-cloud-services/GUID-config-server-refreshing-properties.html


cf update-service cf-hoover-config -c '{"update-git-repos": true }'
cf restage cf-hoover
