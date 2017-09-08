# Secure dockerized Wordpress suitable for integration into a CI pipeline

[![Build Status](https://drone.plat2.leonidasoy.fi/api/badges/leonidas/leonidas-2017/status.svg)](https://drone.plat2.leonidasoy.fi/leonidas/leonidas-2017)

Workspace for WordPress theme development.

## Getting started

Requirements:

* Docker (tested: 17.07 CE)
* Docker Compose (tested: 1.16.0)

The development environment should start up hands-free by simply running

    docker-compose up

Open http://localhost:8000 in your browser. Run the installation wizard, then change the active theme under `Appearance > Themes`.

Now as you make changes under `wp-content/themes/play360`, they should be reflected in real time.

## To update WordPress

Our WordPress core update strategy is based on building new images when WordPress is updated. This is done by

    ./update-dockerfile.sh

This downloads `Dockerfile.dist` and `docker-entrypoint.sh` from [here](https://github.com/docker-library/wordpress/tree/master/php5.6/apache), comments out `VOLUME /var/www/html` and then appends `Dockerfile.footer` to `Dockerfile.dist` to produce the final `Dockerfile`.

## Maintenance mode

When started with `WORDPRESS_MAINTENANCE_MODE=true`, the `wordpress` container will enter **maintenance mode**.

In maintenance mode, the plugin and theme directories are writable by the server. This enables you to install themes and plugins via the Wordpress admin UI.

Outside maintenance mode those directories are read only to prevent unauthorized changes.

When deployed in Kontena, use the `<stack>_maintenance_mode` secret to control maintenance mode:

    # enable maintenance mode
    kontena secret write wordpress_maintenance_mode true
    kontena stack upgrade --deploy wordpress kontena.yml

    # disable maintenance mode
    kontena secret write wordpress_maintenance_mode false
    kontena stack upgrade --deploy wordpress kontena.yml

## Changes to library/wordpress

* Do not `VOLUME /var/www/html` but `VOLUME /var/www/html/wp-content` instead
* Files outside that are read only (owned by `root:www-data`)

## TODO

- [ ] Block PHP files from `wp-content/uploads` using htaccess
- [ ] Install plugins and themes at build time
