# home

The home for ideas and exploration.  Mainly documentation, videos and discussion.

## Resources

### Documentation

* [Background](docs/Background%20on%20cf-toolsuite.pdf)
* Evaluating
  * [Locally](docs/Evaluating%20cf-toolsuite%20locally.pdf)
  * [on Tanzu Application Service](docs/Evaluating%20cf-toolsuite%20on%20TAS.pdf)

#### Community talks

* [The Secret Lives of Java Apps: Stories Told at Runtime](docs/The%20Secret%20Lives%20of%20Java%20Apps%20Stories%20Told%20at%20Runtime.pdf)
  * delivered @ [Seattle Java Users Group](https://www.seajug.org/) (May 21, 2024)

### Pre-built artifacts

* `.jar` files
  * [cf-archivist](https://github.com/cf-toolsuite/cf-archivist/releases)
  * [cf-butler](https://github.com/cf-toolsuite/cf-butler/releases)
  * [cf-hoover](https://github.com/cf-toolsuite/cf-hoover/releases)
  * [cf-hoover-ui](https://github.com/cf-toolsuite/cf-hoover-ui/releases)
  * [spring-boot-starter-runtime-meta-data](https://central.sonatype.com/artifact/org.cftoolsuite.actuator/spring-boot-starter-runtime-metadata)

* Container images on [Docker Hub](https://hub.docker.com/repositories/cftoolsuite)

### Prerequisites

#### Required

* CF API endpoint and admin credentials to a Cloud Foundry foundation (e.g., Tanzu Application Service)

##### Optional

* Operations Manager admin credentials
* VMware Tanzu Network API token

#### Toolset

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

You'll need to author two configuration files named `secrets.cf-butler.{foundation}.json` and `secrets.cf-archivist.{foundation}.json` and place them in the `/tmp/config` directory.  Crib from the samples in [footprints/tas/config](footprints/tas/config).

* [Install](scripts/e2e-install.sh)
* [Uninstall](scripts/e2e-uninstall.sh)
* [Expose curated set of Spring Boot Actuator endpoints](scripts/expose-actuator-endpoints.sh)
* Set Java artifacts [fetch mode](scripts/set-java-artifacts-fetch-mode.sh) on a [cf-butler](https://github.com/cf-toolsuite/cf-butler/blob/main/docs/ENDPOINTS.md#java-applications) instance
* [Update Spring Cloud Config Server instance mirror](scripts/update-config-service-mirrors.sh) backing [cf-hoover](https://github.com/cf-toolsuite/cf-hoover?tab=readme-ov-file#minimum-required-keys) instance
* [Switch](scripts/switch-backend-to-mysql.sh) backend to MySQL

#### With Docker Compose

You'll need to author two configuration files named `butler.env` and `archivist.env` underneath [footprints/local/docker/config](footprints/local/docker/config).  Crib from the `*.sample` files.

* [Build container images](scripts/build-container-images.sh)
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
