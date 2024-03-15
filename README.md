# home

The home for ideas and exploration.  Mainly documentation, videos and discussion.

## Resources

### Pre-built artifacts

* `.jar` files
  * [cf-archivist](https://github.com/cf-toolsuite/cf-archivist/packages/1895036)
  * [cf-butler](https://github.com/cf-toolsuite/cf-butler/packages/809627)
  * [cf-hoover](https://github.com/cf-toolsuite/cf-hoover/packages/809701)
  * [cf-hoover-ui](https://github.com/cf-toolsuite/cf-hoover-ui/packages/809727)
  * [spring-boot-starter-runtime-meta-data](https://github.com/cf-toolsuite/spring-boot-starter-runtime-metadata/packages/2099270)
* Container images on [Docker Hub](https://hub.docker.com/)
  * (coming soon)

### Prerequisites

* CF API endpoint and admin credentials to a Tanzu Application Service foundation
* Operations Manager admin credentials
* VMware Tanzu Network API token

#### Tools

* [gh](https://cli.github.com/)
* [git](https://git-scm.com/downloads)
* [cf](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
* [docker](https://docs.docker.com/desktop/) (make sure you have the compose plugin)
* [http](https://httpie.io/)
* [jq](https://github.com/jqlang/jq)
* [pack](https://github.com/buildpacks/pack)
* [sdk](http://sdkman.io)

### How to

#### On Tanzu Application Service

* [Install](scripts/e2e-install.sh)
* [Uninstall](scripts/e2e-uninstall.sh)
* [Build container images](scripts/build-container-images.sh)
* [Expose curated set of Spring Boot Actuator endpoints](scripts/expose-actuator-endpoints.sh)
* Set Java artifacts [fetch mode](scripts/set-java-artifacts-fetch-mode.sh) on a [cf-butler](https://github.com/cf-toolsuite/cf-butler/blob/main/docs/ENDPOINTS.md#java-applications) instance
* [Update Spring Cloud Config Server instance mirror](scripts/update-config-service-mirrors.sh) backing [cf-hoover](https://github.com/cf-toolsuite/cf-hoover?tab=readme-ov-file#minimum-required-keys) instance
* [Switch](scripts/switch-backend-to-mysql.sh) backend to MySQL

#### With Docker Compose

You'll need to author `butler.env` and `archivist.env` files underneath [footprints/local/docker](footprints/local/docker)/config.  Crib from the `*.sample` files.

* [Startup](footprints/local/startup.sh)
* [Shutdown](footprints/local/shutdown.sh)
* [Show logs for a service](footprints/local/show-logs.sh)
* [Status](footprints/local/status.sh)

#### Work with available endpoints

This is not an exhaustive list.  Refer to respective service documentation for more details.

* Trigger fresh collection on `cf-butler`
  * on TAS: `http POST {cf-butler-route}/collect`
  * w/ Docker Compose: `http POST :8080/collect`
* Trigger cache refresh on `cf-hoover-ui`
  * on TAS: `http POST {cf-hoover-ui-route}/cache/refresh`
  * w/ Docker Compose: `http POST :8083/cache/refresh`
* Trigger cache refresh on `cf-archivist`
  * on TAS: `http POST {cf-archivist-route}/cache/refresh`
  * w/ Docker Compose: `http POST :8081:/cache/refresh`
