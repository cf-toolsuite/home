# home

The home for ideas and exploration.  Mainly documentation, videos and discussion.

## Resources

* Scripts
  * Tanzu Application Service
    * [Install](scripts/e2e-install.sh)
    * [Uninstall](scripts/e2e-uninstall.sh)
    * [Build container images](scripts/build-container-images.sh)
    * [Expose curated set of Spring Boot Actuator endpoints](scripts/expose-actuator-endpoints.sh)
    * Set Java artifacts [fetch mode](scripts/set-java-artifacts-fetch-mode.sh) on a [cf-butler](https://github.com/cf-toolsuite/cf-butler/blob/main/docs/ENDPOINTS.md#java-applications) instance
    * [Update Spring Cloud Config Server instance mirror](scripts/update-config-service-mirrors.sh) backing [cf-hoover](https://github.com/cf-toolsuite/cf-hoover?tab=readme-ov-file#minimum-required-keys) instance
    * [Switch](scripts/switch-backend-to-mysql.sh) backend to MySQL
  * Docker Compose
    * You'll need to author `butler.env` and `archivist.env` files underneath [footprints/local/docker](footprints/local/docker)/config.  Crib from the `*.sample` files.
    * [Startup](footprints/local/startup.sh)
    * [Shutdown](footprints/local/shutdown.sh)
    * [Show logs for a service](footprints/local/show-logs.sh)
    * [Status](footprints/local/status.sh)
  * Tickling endpoints
    * Trigger fresh collection on cf-butler
      * on TAS: `http POST {cf-butler-route}/collect`
      * on Docker Compose: `http POST :8080/collect`
    * Trigger cache refresh on cf-hoover-ui
      * on TAS: `http POST {cf-hoover-ui-route}/cache/refresh`
      * on Docker Compose: `http POST :8083/cache/refresh`
    * Trigger cache refresh on cf-archivist
      * on TAS: `http POST {cf-archivist-route}/cache/refresh`
      * on Docker Compose: `http POST :8081:/cache/refresh`
