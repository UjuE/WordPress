#Copied and edited from https://github.com/docker-library/wordpress/blob/4e108fd7f80ca167ea0f38531e2ae26b3f19783e/php7.1/apache/Dockerfile
FROM php:7.3-apache

ENV AUTH_KEY='put your your unique phrase here'
ENV SECURE_AUTH_KEY='put your your unique phrase here'
ENV LOGGED_IN_KEY='put your your unique phrase here'
ENV NONCE_KEY='put your your unique phrase here'
ENV SECURE_AUTH_SALT='put your your unique phrase here'
ENV LOGGED_IN_SALT='put your your unique phrase here'
ENV NONCE_SALT='put your your unique phrase here'
ENV DB_TABLE_PREFIX='wp_'
ENV DB_NAME=''
ENV DB_USER=''
ENV DB_PASSWORD=''
ENV DB_HOST=''
ENV HOSTNAME='example.com'

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache zip; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

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

WORKDIR /var/www/html

ADD . /var/www/html/

RUN chmod 777 /usr/local/bin/apache2-foreground;

CMD ["/usr/local/bin/apache2-foreground"]