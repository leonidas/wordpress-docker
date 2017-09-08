FROM php:5.6-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y ssmtp \
		libjpeg-dev \
		libpng-dev \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache
# TODO consider removing the *-dev deps and only keeping the necessary lib* packages

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite expires

#VOLUME /var/www/html

ENV WORDPRESS_VERSION 4.8.1
ENV WORDPRESS_SHA1 5376cf41403ae26d51ca55c32666ef68b10e35a4

RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]

# These lines will be appended from Dockerfile.footer to Dockerfile.dist to produce a working Dockerfile
# If you change Dockerfile.footer, remember to re-run wordpress/update-dockerfile.sh.
# Do not edit the resulting Dockerfile manually. Changes will be lost.
COPY htaccess /var/www/html/.htaccess

# Hack to restore backup
# COPY wp-content.tar.gz /usr/src/

RUN cd /var/www/html \
    && tar cf - --one-file-system -C /usr/src/wordpress . | tar xf -

# The contents of wp-content/ will be copied to /var/www/html/wp-content (a volume!) by docker-entrypoint.footer.sh
# COPY wp-content /usr/src/wp-content

RUN mkdir -p wp-content/uploads \
    && chown -R root:www-data . \
    && chown -R www-data:www-data wp-content \
    && find . -type d -exec chmod 755 \{\} + \
    && find . -type f -exec chmod 644 \{\} + \
    && chmod -R g+w wp-content/uploads wp-content/plugins \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && echo "define('FS_METHOD', 'direct');" >> /var/www/html/wp-config-sample.php \
    && echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini

VOLUME /var/www/html/wp-content
